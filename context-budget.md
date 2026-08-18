# The agent's read budget

Every session of the agent that maintains this vault reads three files before it
is allowed to do anything: the behavior manual (modes, pipeline, rules), the
vault rulebook, and the tag schema. That set grew to **595 lines / 43,065 bytes**
without anyone deciding it should.

Nothing was wrong with any individual file. The problem is structural: a
mandatory read set is a tax paid by every session, including the ones that only
needed to answer one question — and it is the first thing to get silently
truncated when a runtime has an output cap.

---

## The failure that forced the issue

A second runtime (a different CLI agent, same three files) capped tool output at
**10,000 tokens per read**. Measured, not guessed: six truncation markers in its
session logs, each keeping exactly 10k tokens and dropping the rest.

The trap was in *how* it read them. Each file individually fit under the cap.
Only the concatenated read of all three — the shell habit of `cat a b c` in one
call — overflowed, and only by a few percent. So the loss was small, silent, and
landed on **the end of the last file**, which is exactly where the newest rules
sit in an append-shaped document.

Two fixes, both cheap:

- **Read the files separately. Never concatenate them.** Written into the manual
  itself, in the orientation step, so every runtime inherits it rather than each
  adapter having to know.
- **A physical end-of-file sentinel line.** A literal `<FILE>-EOF` marker as the
  last line of the manual. A read that does not end with the sentinel is a
  partial read, and the agent can tell the difference between "I read the file"
  and "I read most of the file." Before the sentinel, those two outcomes were
  indistinguishable from inside the session.

The byte cut below was justified separately — on context pollution, not on the
cap — but the cap is what made anyone measure.

---

## What actually removed the bytes

Three moves, in descending yield.

### 1. Dedup on an ownership split

The shared conventions were stated in two places: the human-owned rulebook and
the agent's behavior manual. Not contradicting — just restated, which is worse,
because two copies of a rule drift into two rules within a month.

The fix was not "delete one." It was to give each shared convention exactly
**one owner file**, and make the other file cross-reference it *by rule number*
rather than restating it. The rulebook now owns every shared schema and
convention outright; the manual says "per rule 11" and moves on.

Note which way the ownership went: to the file that already **overrides** the
other in a conflict. Single-sourcing into the losing file would have created a
new class of bug.

### 2. Evacuate the stories off the startup path

Every good rule in this system has a dated incident attached, and the incident
is why anyone follows the rule. It is also, for the agent, pure overhead on the
four-hundredth read.

The dated narratives moved into a separate incidents file that is **not** part
of the startup set. Each live rule kept two things: the one line that tells you
*where its boundary is* (the discriminator you actually need to apply it), and
an anchor link to its story for whoever wants it.

This is the counterintuitive one, so state it plainly: **the story is what makes
a rule stick with a human and what makes it expensive for a machine.** Keep both,
store them apart, link them.

### 3. Densify

Ordinary compression of the remainder: tables instead of prose lists, one-time
migration bookkeeping moved to an archive file, worked examples cut to the shape
they were demonstrating.

### The measured result

| File | Before | After | Change |
|---|---|---|---|
| Behavior manual | 27,757 B | 21,881 B | −21% |
| Vault rulebook | 9,603 B | 8,491 B | −12% |
| Tag schema | 5,705 B | 3,874 B | −32% |
| **Combined startup set** | **43,065 B** | **34,246 B** | **−20%** |

Target was "under 35 KB combined." It cleared by 754 bytes, which is close
enough to admit that the target was a round number chosen to force the work, not
a threshold anything actually breaks at.

---

## What got rejected

Recorded because the rejected options are the ones you will think of first.

| Approach | Why it lost |
|---|---|
| An author-time compile step (write long, generate a short runtime copy) | A build step for prose rots the moment someone edits the generated copy, and someone always does. Two files that must agree, with no enforcement. |
| Split the manual into one file per mode | Every session still needs the shared half, so you have not cut the mandatory set — you have added a routing decision before the agent knows which mode it is in. |
| Offset reads ("read lines 1–120 at startup") | Brittle against any edit. A rule that moves down twenty lines silently stops being read, and nothing errors. |
| A rule registry with lazy loading | The agent cannot know which rule it needs before it has read enough to know what it is doing. Lazy-loading rules is lazy-loading the thing that decides what to load. |
| Treat the size target as the goal | The goal is that a session reads what it needs and nothing else. Bytes are the proxy; optimizing the proxy directly is how you end up with a terse file nobody can follow. |

---

## Proving the cut didn't lose a rule

A 20% cut to the file that governs an agent's behavior is only safe if you can
show nothing behavioral went with it. What was actually run:

- **Before/after inventory of every heading and every imperative**, reconciled
  item by item. This caught one accidentally split heading and nothing else.
- **Every cross-reference resolved**: all "per rule N" pointers, all anchor links
  into the evacuated incidents file.
- **The vault link auditor** run afterwards: zero malformed links, zero new
  orphan nodes.
- **Behavioral dry-runs** of the representative modes against the new text.

The inventory is the load-bearing one. Reading the diff tells you what changed;
only the inventory tells you what *disappeared*.

---

## The generalizable part

1. **Measure the mandatory read set as a number.** Nobody notices prose growing.
   Everybody notices `43,065 bytes, every session`.
2. **Concatenated reads are where truncation hides.** If a runtime caps output,
   the cap lands on the tail of the last file, and the tail is where new rules
   go. Read separately, and put a sentinel at the end of anything long enough to
   be cut.
3. **Dedup by assigning ownership, not by deleting.** One owner per convention;
   everyone else cites it by number.
4. **Separate the rule from the reason.** Rules are for every run. Reasons are
   for the run where someone asks "why does this exist?"
5. **A rule that is never read is not a rule**, and neither is one buried past
   the point where the reader's budget ran out.
