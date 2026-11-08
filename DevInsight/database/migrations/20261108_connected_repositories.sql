create table if not exists public.connected_repositories (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users (id) on delete cascade,
    github_repository_id bigint not null,
    repository_full_name text not null,
    repository_url text not null,
    repository_owner text not null,
    repository_name text not null,
    description text,
    default_branch text,
    primary_language text,
    is_private boolean not null default false,
    stargazers_count integer not null default 0,
    forks_count integer not null default 0,
    github_created_at timestamptz,
    github_updated_at timestamptz,
    github_pushed_at timestamptz,
    connected_at timestamptz not null default now(),
    last_synced_at timestamptz,
    cached_summary jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint connected_repositories_user_repository_key
        unique (user_id, github_repository_id)
);

alter table public.connected_repositories
    add column if not exists stargazers_count integer not null default 0,
    add column if not exists forks_count integer not null default 0,
    add column if not exists github_created_at timestamptz,
    add column if not exists github_updated_at timestamptz,
    add column if not exists github_pushed_at timestamptz;

create index if not exists connected_repositories_user_connected_idx
    on public.connected_repositories (user_id, connected_at desc);

alter table public.connected_repositories enable row level security;

drop policy if exists "Users can read their own connected repositories"
    on public.connected_repositories;
create policy "Users can read their own connected repositories"
    on public.connected_repositories
    for select
    to authenticated
    using ((select auth.uid()) = user_id);

revoke all on table public.connected_repositories from anon, authenticated;
grant select on table public.connected_repositories to authenticated;
grant select, insert, update, delete
    on table public.connected_repositories to service_role;
