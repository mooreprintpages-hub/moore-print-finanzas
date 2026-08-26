alter table public.inventory_movements
  drop constraint if exists inventory_movements_movement_type_check;

alter table public.inventory_movements
  add constraint inventory_movements_movement_type_check
  check (movement_type in (
    'purchase',
    'purchase_receipt',
    'reservation',
    'release',
    'consumption',
    'transfer',
    'adjustment',
    'waste',
    'return',
    'supplier_return',
    'sample',
    'damage'
  ));
