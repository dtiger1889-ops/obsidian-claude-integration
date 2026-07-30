# extract_approvals.ps1 -- build/refresh the append-only approval-pipeline ledger.
#
# Scans an Obsidian vault for notes carrying `approval_stage` frontmatter and merges
# them into a JSON ledger. APPEND-ONLY BY DESIGN: a record already in the ledger is
# updated in place but NEVER removed, so a note that later gets filed elsewhere,
# renamed, merged, or deleted keeps its proposal-vs-actual data point.
#
# That is the whole reason this file exists. Querying the vault directly does not
# work: resolving an item destroys its own evidence. A filed note moves out of the
# inbox where the "needs review" filter can't see it; a rejected note is deleted.
# What is left in the vault is a biased sample of the unresolved.
#
# Run it at the end of every inbox sweep, and again after a batch is resolved.
#
#   pwsh -File ./extract_approvals.ps1 -VaultRoot 'C:\path\to\Vault' -LedgerPath '.\approval_ledger.json'
#
# See approval-staging.md for the frontmatter schema and what the numbers meant.

param(
    [Parameter(Mandatory = $true)]
    [string]$VaultRoot,

    [string]$LedgerPath = (Join-Path $PSScriptRoot 'approval_ledger.json'),

    # Folder-name fragments to skip: the vault trash, and any symlink/junction
    # pointing at a code workspace you don't want scanned.
    [string[]]$ExcludePathFragments = @('\.trash\')
)

$Today = Get-Date -Format 'yyyy-MM-dd'

# Frontmatter fields carried into the ledger. Rename `user_dest` to whatever your
# override field is called; it must match the .base file and the notes.
$Fields = @(
    'created', 'item_type', 'active_todo', 'approval_stage', 'approve', 'hold',
    'proposed_dest', 'user_dest', 'final_dest', 'pipeline_outcome',
    'pipeline_started', 'pipeline_finished', 'claude_note'
)

function Get-Frontmatter {
    param([string]$Path)
    $lines = Get-Content -LiteralPath $Path -Encoding UTF8 -ErrorAction Stop
    if ($lines.Count -lt 2 -or $lines[0].Trim() -ne '---') { return $null }

    $end = -1
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') { $end = $i; break }
    }
    if ($end -lt 0) { return $null }

    $fm = @{}
    $currentKey = $null
    for ($i = 1; $i -lt $end; $i++) {
        $line = $lines[$i]
        if ($line -match '^([A-Za-z_][A-Za-z0-9_]*):\s*(.*)$') {
            $currentKey = $matches[1]
            $val = $matches[2].Trim()
            # strip the surrounding quotes YAML may carry
            if ($val.Length -ge 2 -and (($val[0] -eq '"' -and $val[-1] -eq '"') -or ($val[0] -eq "'" -and $val[-1] -eq "'"))) {
                $val = $val.Substring(1, $val.Length - 2)
            }
            $fm[$currentKey] = $val
        }
        elseif ($currentKey -and $line -match '^\s+\S') {
            # continuation / list item -- append so a multi-line note survives
            $fm[$currentKey] = ($fm[$currentKey] + ' ' + $line.Trim()).Trim()
        }
    }
    return $fm
}

# ---- load existing ledger -------------------------------------------------
$ledger = @{}
if (Test-Path -LiteralPath $LedgerPath) {
    $raw = Get-Content -LiteralPath $LedgerPath -Raw -Encoding UTF8
    if ($raw.Trim()) {
        foreach ($rec in (ConvertFrom-Json $raw)) { $ledger[$rec.id] = $rec }
    }
}
$preCount = $ledger.Count

# ---- scan the vault -------------------------------------------------------
$seen = 0
$files = Get-ChildItem -LiteralPath $VaultRoot -Recurse -Filter '*.md' -File -ErrorAction SilentlyContinue |
    Where-Object {
        $full = $_.FullName
        -not ($ExcludePathFragments | Where-Object { $full -match [regex]::Escape($_) })
    }

foreach ($f in $files) {
    $fm = Get-Frontmatter -Path $f.FullName
    if (-not $fm -or -not $fm.ContainsKey('approval_stage')) { continue }
    $seen++

    # Stable id: title + created stamp, so a re-filed or renamed note still matches
    # on `created`. Without this, moving a note to its destination would create a
    # duplicate record and the agree/override split would double-count.
    $title = [IO.Path]::GetFileNameWithoutExtension($f.Name)
    $id    = '{0}|{1}' -f $title, ($fm['created'])

    $relPath = $f.FullName.Substring($VaultRoot.Length).TrimStart('\')

    if ($ledger.ContainsKey($id)) {
        $rec = $ledger[$id]
    } else {
        $rec = [pscustomobject]@{ id = $id; title = $title; first_seen = $Today }
        $ledger[$id] = $rec
    }

    foreach ($k in $Fields) {
        $v = if ($fm.ContainsKey($k)) { $fm[$k] } else { $null }
        $rec | Add-Member -NotePropertyName $k -NotePropertyValue $v -Force
    }
    $rec | Add-Member -NotePropertyName 'current_path' -NotePropertyValue $relPath -Force
    $rec | Add-Member -NotePropertyName 'last_seen'    -NotePropertyValue $Today   -Force
    $rec | Add-Member -NotePropertyName 'vanished'     -NotePropertyValue $false   -Force
}

# ---- mark records whose note is gone (deleted / merged) --------------------
# Kept, never dropped: a vanished record is often the most informative one.
$vanished = 0
foreach ($id in @($ledger.Keys)) {
    if ($ledger[$id].last_seen -ne $Today) {
        $ledger[$id] | Add-Member -NotePropertyName 'vanished' -NotePropertyValue $true -Force
        $vanished++
    }
}

# ---- write ----------------------------------------------------------------
$out = $ledger.Values | Sort-Object { $_.pipeline_started }, { $_.title }
($out | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $LedgerPath -Encoding UTF8

# ---- report ---------------------------------------------------------------
$resolved   = @($out | Where-Object { $_.approval_stage -ne 'review' })
$approved   = @($resolved | Where-Object { $_.pipeline_outcome -eq 'approved-and-filed' }).Count
$redirected = @($resolved | Where-Object { $_.pipeline_outcome -eq 'redirected-and-filed' }).Count
$inReview   = @($out | Where-Object { $_.approval_stage -eq 'review' }).Count
$rate = if ($resolved.Count) { [math]::Round(100 * $redirected / $resolved.Count) } else { 0 }

Write-Output "notes scanned with approval frontmatter : $seen"
Write-Output "ledger records  : $($ledger.Count)  (was $preCount)"
Write-Output "resolved        : $($resolved.Count)   in review: $inReview   vanished-but-retained: $vanished"
Write-Output "agreed          : $approved"
Write-Output "overridden      : $redirected  ($rate% of resolved)"
Write-Output "ledger -> $LedgerPath"
