#!/usr/bin/env python3
"""
generate_from_facts.py — Generate trivia questions from pre-extracted source facts.

For each source entry in a topic's sources file, reads its facts and existing
questions, calls Claude to generate new questions, then appends them to the
topic's questions file via append_questions.py.

No questions are generated that already exist for the source.

Usage:
    python3 .claude/skills/generate-questions/scripts/generate_from_facts.py [topicId ...]
    python3 ... french_literature --sources src_albert_camus src_victor_hugo
    python3 ... french_literature --count 10
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

SOURCES_DIR = Path("assets/questions/sources")
TOPICS_DIR  = Path("assets/questions/topics")
SCRIPTS_DIR = Path(".claude/skills/generate-questions/scripts")

DEFAULT_COUNT = 15
BATCH_SIZE    = 10  # max questions per Claude call

TOPICS: list[str] = [
    "coffee", "coffee_brewing", "deep_sea", "crocheting", "water_bodies",
    "socks", "adhd", "therapy", "pharmaceutical_drugs", "recreational_drugs",
    "medicine", "countries", "dictionaries", "linguistics", "theology",
    "medieval_history", "footwear", "perfumes", "plastics", "handheld_devices",
    "human_geography", "tennis", "puzzles", "west_african_history",
    "french_literature", "lily_mayne", "rocks", "agatha_christie", "anatomy",
    "autism", "bridges",
]

GENERATE_PROMPT = """\
You are a trivia question generator for a medieval castle game called Mind Mazeish.

Topic: {topic_id}
topicCategoryId: {topic_category_id}
superCategoryId: {super_category_id}
sourceId: {source_id}

Generate exactly {count} trivia questions using ONLY the facts listed below.
Each question must be grounded in a specific fact — do not use outside knowledge.

Facts:
{facts_text}

Existing questions for this source (DO NOT duplicate — avoid same question, same answer, or same core fact):
{existing_questions_text}

Next available question ID: {next_id}
All IDs already in use (never reuse these): {existing_ids_json}

Rules:
- Output ONLY a raw JSON array — no markdown fences, no preamble, no explanation
- Each question must follow this exact schema:
  {{
    "id": "{topic_id}_NNN",
    "question": "...",
    "correctAnswers": ["..."],
    "wrongAnswers": ["...", "...", "...", "..."],
    "funFact": "1-2 sentences shown after the answer.",
    "sourceId": "{source_id}",
    "topicId": "{topic_id}",
    "topicCategoryId": "{topic_category_id}",
    "superCategoryId": "{super_category_id}",
    "difficulty": "easy" | "medium" | "hard"
  }}

ID numbering:
- Start from {next_id} and increment for each question
- Format: {topic_id}_NNN where NNN is zero-padded to at least 3 digits
- Never reuse an ID from the "all IDs already in use" list above

Difficulty spread — aim for a balanced mix:
- easy: widely known fact; casual fan would know it; always exactly 1 correct answer
- medium: requires genuine interest; comparative, numerical, or contextual; 1-2 correct answers
- hard: obscure or specialist knowledge; 1-3 correct answers; odd-one-out or open-ended style encouraged

correctAnswers: 1-3 equally-valid items. The game picks one at random to display,
  so every question wording must be satisfiable by any single correct answer alone.
  Never use "select all that apply" framing.

wrongAnswers: 8-12 items (minimum 4, maximum 20). Must be plausible —
  same category, era, or scale as the correct answer.

funFact: 1-2 sentences revealed after answering. May include context beyond the question.

Output (raw JSON array only):"""


# ──────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────

def get_topic_meta(topic_id: str) -> tuple[str, str]:
    """Return (topicCategoryId, superCategoryId) from the first existing question."""
    topic_file = TOPICS_DIR / f"{topic_id}.json"
    if topic_file.exists():
        questions = json.loads(topic_file.read_text(encoding="utf-8"))
        if questions:
            q = questions[0]
            return q.get("topicCategoryId", ""), q.get("superCategoryId", "")
    return "", ""


def get_topic_stats(topic_id: str) -> dict:
    result = subprocess.run(
        [sys.executable, str(SCRIPTS_DIR / "topic_stats.py"), "--topic", topic_id],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        return {"count": 0, "nextId": f"{topic_id}_001", "existingIds": []}
    return json.loads(result.stdout)


def get_existing_questions_for_source(topic_id: str, source_id: str) -> list[dict]:
    """Return questions in the topic file that belong to this source."""
    topic_file = TOPICS_DIR / f"{topic_id}.json"
    if not topic_file.exists():
        return []
    questions = json.loads(topic_file.read_text(encoding="utf-8"))
    return [q for q in questions if q.get("sourceId") == source_id]


def next_available_id(all_ids: list[str], topic_id: str) -> str:
    """Return the next unused ID string for the topic."""
    prefix = topic_id + "_"
    max_n = 0
    for qid in all_ids:
        if qid.startswith(prefix):
            try:
                max_n = max(max_n, int(qid[len(prefix):]))
            except ValueError:
                pass
    return f"{topic_id}_{max_n + 1:03d}"


def call_claude(prompt: str) -> list[dict]:
    result = subprocess.run(
        ["claude", "-p", prompt],
        capture_output=True, text=True, timeout=300,
    )
    if result.returncode != 0:
        print(f"    ✗ claude failed (exit {result.returncode}): {result.stderr[:300]}", file=sys.stderr)
        return []
    output = result.stdout.strip()
    start = output.find("[")
    end   = output.rfind("]") + 1
    if start == -1 or end <= 0:
        print(f"    ✗ no JSON array in claude output; snippet: {output[:200]}", file=sys.stderr)
        return []
    try:
        questions = json.loads(output[start:end])
        if isinstance(questions, list):
            return questions
    except json.JSONDecodeError as exc:
        print(f"    ✗ JSON parse error: {exc}", file=sys.stderr)
    return []


def append_questions(topic_id: str, questions: list[dict]) -> bool:
    result = subprocess.run(
        [sys.executable, str(SCRIPTS_DIR / "append_questions.py"), "--topic", topic_id],
        input=json.dumps(questions, ensure_ascii=False),
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        print(f"    ✗ append failed: {result.stderr[:300]}", file=sys.stderr)
        return False
    print(f"    {result.stdout.strip()}")
    if result.stderr.strip():
        print(f"    {result.stderr.strip()}", file=sys.stderr)
    return True


# ──────────────────────────────────────────────
# Core logic
# ──────────────────────────────────────────────

def process_topic(topic_id: str, only_sources: set[str] | None, count: int) -> bool:
    sources_file = SOURCES_DIR / f"{topic_id}.json"
    if not sources_file.exists():
        print(f"  ✗ {sources_file} not found", file=sys.stderr)
        return False

    topic_cat_id, super_cat_id = get_topic_meta(topic_id)
    if not topic_cat_id:
        print(f"  ✗ cannot determine topicCategoryId for {topic_id} — add at least one question first", file=sys.stderr)
        return False

    sources: list[dict] = json.loads(sources_file.read_text(encoding="utf-8"))
    stats = get_topic_stats(topic_id)

    # Track IDs generated this run so next_id stays accurate across sources
    generated_ids: list[str] = []
    any_success = False

    for src in sources:
        source_id = src.get("id", "")
        if only_sources and source_id not in only_sources:
            continue

        facts: list[dict] = src.get("facts", [])
        if not facts:
            print(f"  ✗ {source_id}: no facts — run relearn first", file=sys.stderr)
            continue

        existing_qs = get_existing_questions_for_source(topic_id, source_id)
        all_existing_ids = stats["existingIds"] + generated_ids
        nxt = next_available_id(all_existing_ids, topic_id)

        batches = [
            BATCH_SIZE if remaining > BATCH_SIZE else remaining
            for remaining in [count - b * BATCH_SIZE for b in range((count + BATCH_SIZE - 1) // BATCH_SIZE)]
        ]
        total_batches = len(batches)
        print(f"  → {source_id}  ({len(facts)} facts, {len(existing_qs)} existing questions, {count} wanted in {total_batches} batch(es))")

        facts_text = "\n".join(f"- {f['text']}" for f in facts)
        source_success = False

        # Keep a running list of questions already written for this source, so each
        # subsequent batch knows what to avoid.
        written_this_source: list[dict] = list(existing_qs)

        for batch_num, batch_count in enumerate(batches, start=1):
            all_existing_ids = stats["existingIds"] + generated_ids
            nxt = next_available_id(all_existing_ids, topic_id)

            if total_batches > 1:
                print(f"    batch {batch_num}/{total_batches} ({batch_count} questions, next id: {nxt})")

            if written_this_source:
                existing_questions_text = "\n".join(
                    f"- [{q['id']}] {q['question']}  →  {q['correctAnswers']}"
                    for q in written_this_source
                )
            else:
                existing_questions_text = "(none yet)"

            prompt = GENERATE_PROMPT.format(
                topic_id=topic_id,
                topic_category_id=topic_cat_id,
                super_category_id=super_cat_id,
                source_id=source_id,
                count=batch_count,
                facts_text=facts_text,
                existing_questions_text=existing_questions_text,
                next_id=nxt,
                existing_ids_json=json.dumps(all_existing_ids),
            )

            questions = call_claude(prompt)
            if not questions:
                print(f"    ✗ no questions generated", file=sys.stderr)
                continue

            generated_ids.extend(q.get("id", "") for q in questions if q.get("id"))
            written_this_source.extend(questions)

            if append_questions(topic_id, questions):
                source_success = True

        if source_success:
            any_success = True

    return any_success


# ──────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────

def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(
        description="Generate trivia questions from source facts and append to topic files.",
        epilog=(
            "Examples:\n"
            "  %(prog)s                                                     # all default topics\n"
            "  %(prog)s french_literature                                   # all sources in topic\n"
            "  %(prog)s french_literature --sources src_albert_camus        # one source\n"
            "  %(prog)s french_literature --count 10                        # 10 questions per source\n"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("topics", nargs="*", help="Topic IDs to process (default: all in TOPICS list)")
    parser.add_argument("--sources", "-s", nargs="+", metavar="SOURCE_ID",
                        help="Process only these source IDs within the given topic(s)")
    parser.add_argument("--count", "-n", type=int, default=DEFAULT_COUNT,
                        help=f"Questions to generate per source (default: {DEFAULT_COUNT})")
    args = parser.parse_args()

    work = args.topics if args.topics else TOPICS
    only_sources = set(args.sources) if args.sources else None

    missing = [t for t in work if not (SOURCES_DIR / f"{t}.json").exists()]
    if missing:
        print(f"No sources file found for: {', '.join(missing)}", file=sys.stderr)
        sys.exit(1)

    scope = f" (sources: {', '.join(sorted(only_sources))})" if only_sources else ""
    print(f"Generate from facts: {len(work)} topic(s), {args.count} questions/source{scope}\n")

    success = 0
    for topic_id in work:
        print(f"→ {topic_id}")
        if process_topic(topic_id, only_sources, args.count):
            success += 1

    print(f"\nDone: {success}/{len(work)} succeeded")
    if success < len(work):
        sys.exit(1)


if __name__ == "__main__":
    main()
