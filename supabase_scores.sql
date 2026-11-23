-- Run once in Supabase SQL Editor (same project as web Pixel Orbit)

create table if not exists public.po_scores (
  id bigserial primary key,
  player_id text not null,
  display_name text not null default 'Pilot',
  score int not null default 0,
  wave int not null default 0,
  mode text not null default 'classic',
  created_at timestamptz default now()
);

create index if not exists po_scores_score_idx on public.po_scores (score desc);
create index if not exists po_scores_mode_idx on public.po_scores (mode, score desc);

alter table public.po_scores enable row level security;

drop policy if exists "po_scores_read" on public.po_scores;
drop policy if exists "po_scores_insert" on public.po_scores;

-- Public read leaderboard (anon ok)
create policy "po_scores_read" on public.po_scores
  for select to anon, authenticated using (true);

-- Anyone can submit a score (simple arcade leaderboard)
create policy "po_scores_insert" on public.po_scores
  for insert to anon, authenticated with check (score >= 0 and score < 10000000);
