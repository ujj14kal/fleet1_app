-- Supabase fix for transporter driver search and driver dashboard assignments.
-- Run this in the Supabase SQL editor as the project owner.

-- Required for REST/Data API access by logged-in app users.
grant usage on schema public to authenticated;
grant select on public.profiles to authenticated;
grant select, update on public.drivers to authenticated;
grant select on public.transporters to authenticated;
grant select, update on public.shipments to authenticated;
grant select on public.shipment_assignments to authenticated;
grant insert on public.shipment_status_updates to authenticated;

alter table public.profiles enable row level security;
alter table public.drivers enable row level security;
alter table public.transporters enable row level security;
alter table public.shipments enable row level security;
alter table public.shipment_assignments enable row level security;
alter table public.shipment_status_updates enable row level security;

-- Profiles: app users can read profiles, including driver profiles for search.
drop policy if exists profiles_select_authenticated on public.profiles;
create policy profiles_select_authenticated
  on public.profiles
  for select
  to authenticated
  using (true);

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own
  on public.profiles
  for insert
  to authenticated
  with check (id = auth.uid());

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
  on public.profiles
  for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- Drivers: every logged-in app user can search the driver table.
-- Assignment is not tied to saved ownership.
-- Saved-list ownership is stored separately in drivers.transporter_id.
drop policy if exists drivers_select_authenticated on public.drivers;
drop policy if exists drivers_select_transporter_or_self on public.drivers;
drop policy if exists drivers_select_all_authenticated on public.drivers;
create policy drivers_select_all_authenticated
  on public.drivers
  for select
  to authenticated
  using (true);

drop policy if exists drivers_insert_own on public.drivers;
create policy drivers_insert_own
  on public.drivers
  for insert
  to authenticated
  with check (id = auth.uid());

drop policy if exists drivers_update_own on public.drivers;
create policy drivers_update_own
  on public.drivers
  for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- Transporters may save an unsaved driver to their list, or update a driver
-- already saved to their own list. They cannot steal a driver saved by another
-- transporter. This does not block assigning that driver to a shipment.
drop policy if exists drivers_update_transporter_saved_list on public.drivers;
create policy drivers_update_transporter_saved_list
  on public.drivers
  for update
  to authenticated
  using (
    transporter_id is null
    or exists (
      select 1
      from public.transporters t
      where t.id = drivers.transporter_id
        and t.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.transporters t
      where t.id = drivers.transporter_id
        and t.user_id = auth.uid()
    )
  );

-- Transporters: needed so transporter-owned shipment policies can identify the logged-in transporter.
drop policy if exists transporters_select_own on public.transporters;
create policy transporters_select_own
  on public.transporters
  for select
  to authenticated
  using (user_id = auth.uid());

-- Transporter can see shipment assignment rows that belong to their transporter record.
drop policy if exists shipment_assignments_select_own_transporter on public.shipment_assignments;
create policy shipment_assignments_select_own_transporter
  on public.shipment_assignments
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.transporters t
      where t.id = shipment_assignments.transporter_id
        and t.user_id = auth.uid()
    )
  );

-- Shipments are visible to assigned transporters and assigned drivers.
drop policy if exists shipments_select_transporter_or_driver on public.shipments;
create policy shipments_select_transporter_or_driver
  on public.shipments
  for select
  to authenticated
  using (
    driver_id = auth.uid()
    or exists (
      select 1
      from public.shipment_assignments sa
      join public.transporters t on t.id = sa.transporter_id
      where sa.shipment_id = shipments.id
        and t.user_id = auth.uid()
    )
  );

-- Transporter can assign/change the driver on shipments assigned to them.
drop policy if exists shipments_update_own_transporter_assignment on public.shipments;
create policy shipments_update_own_transporter_assignment
  on public.shipments
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.shipment_assignments sa
      join public.transporters t on t.id = sa.transporter_id
      where sa.shipment_id = shipments.id
        and t.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.shipment_assignments sa
      join public.transporters t on t.id = sa.transporter_id
      where sa.shipment_id = shipments.id
        and t.user_id = auth.uid()
    )
  );

drop policy if exists shipment_status_updates_insert_authenticated on public.shipment_status_updates;
create policy shipment_status_updates_insert_authenticated
  on public.shipment_status_updates
  for insert
  to authenticated
  with check (true);

-- Optional sanity checks after running:
-- select id, full_name, phone from public.drivers where full_name ilike '%billa%';
-- select id, full_name, phone, role from public.profiles where role = 'driver';
