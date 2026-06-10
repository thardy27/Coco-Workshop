# Plan: Generate Order Item Strings

## Context

Tables (all in `TIL_PLAYGROUND.CS2_PIZZA_RUNNER`):

| Table | Key columns |
|-------|-------------|
| CUSTOMER_ORDERS | ORDER_ID, CUSTOMER_ID, PIZZA_ID, EXCLUSIONS (csv), EXTRAS (csv) |
| PIZZA_NAMES | PIZZA_ID, PIZZA_NAME ("Meatlovers", "Vegetarian") |
| PIZZA_TOPPINGS | TOPPING_ID, TOPPING_NAME |

`EXCLUSIONS` and `EXTRAS` are VARCHAR(4) containing comma-separated topping IDs (e.g. `'2, 6'`) or empty string / `'null'` literal.

Target output format per row:
```
Meatlovers - Exclude Cheese, Bacon - Extra Mushrooms, Peppers
```

## Implementation

Single query approach:

1. Assign each `CUSTOMER_ORDERS` row a unique row number (no PK exists).
2. Use `SPLIT_TO_TABLE` in lateral joins to explode exclusions and extras into individual topping IDs.
3. Join each topping ID to `PIZZA_TOPPINGS` for the name.
4. `LISTAGG` the exclusion names and extra names back per row.
5. Concatenate: `pizza_name || optional(' - Exclude ' || excl_list) || optional(' - Extra ' || extra_list)`.

Key edge cases:
- Empty string `''` and literal `'null'` both mean "no exclusions/extras" — filter with `NULLIF(NULLIF(col, ''), 'null')`.

```sql
WITH numbered_orders AS (
  SELECT
    ROW_NUMBER() OVER (ORDER BY order_id, customer_id, pizza_id) AS rn,
    *
  FROM TIL_PLAYGROUND.CS2_PIZZA_RUNNER.CUSTOMER_ORDERS
),

exclusions AS (
  SELECT
    o.rn,
    TRIM(s.value) AS topping_id
  FROM numbered_orders o,
    LATERAL SPLIT_TO_TABLE(NULLIF(NULLIF(o.exclusions, ''), 'null'), ',') s
),

extras AS (
  SELECT
    o.rn,
    TRIM(s.value) AS topping_id
  FROM numbered_orders o,
    LATERAL SPLIT_TO_TABLE(NULLIF(NULLIF(o.extras, ''), 'null'), ',') s
),

excl_names AS (
  SELECT e.rn, LISTAGG(t.topping_name, ', ') WITHIN GROUP (ORDER BY t.topping_name) AS excl_list
  FROM exclusions e
  JOIN TIL_PLAYGROUND.CS2_PIZZA_RUNNER.PIZZA_TOPPINGS t ON t.topping_id = e.topping_id::INT
  GROUP BY e.rn
),

extra_names AS (
  SELECT e.rn, LISTAGG(t.topping_name, ', ') WITHIN GROUP (ORDER BY t.topping_name) AS extra_list
  FROM extras e
  JOIN TIL_PLAYGROUND.CS2_PIZZA_RUNNER.PIZZA_TOPPINGS t ON t.topping_id = e.topping_id::INT
  GROUP BY e.rn
)

SELECT
  o.order_id,
  o.customer_id,
  o.pizza_id,
  pn.pizza_name
    || COALESCE(' - Exclude ' || en.excl_list, '')
    || COALESCE(' - Extra ' || xn.extra_list, '')
    AS order_item
FROM numbered_orders o
JOIN TIL_PLAYGROUND.CS2_PIZZA_RUNNER.PIZZA_NAMES pn ON pn.pizza_id = o.pizza_id
LEFT JOIN excl_names en ON en.rn = o.rn
LEFT JOIN extra_names xn ON xn.rn = o.rn
ORDER BY o.rn;
```

## Verification

Run the query and confirm:
- 14 rows returned (one per customer_orders row)
- Row with ORDER_ID=4, PIZZA_ID=1 shows `Meatlovers - Exclude Cheese`
- Row with ORDER_ID=9 shows `Meatlovers - Exclude Cheese - Extra Bacon, Chicken`
- Row with ORDER_ID=10 (second pizza) shows `Meatlovers - Exclude BBQ Sauce, Mushrooms - Extra Bacon, Cheese`
- Plain orders (no exclusions/extras) show just the pizza name

## Critical Files

- TIL_PLAYGROUND.CS2_PIZZA_RUNNER.CUSTOMER_ORDERS - source rows with CSV exclusions/extras
- TIL_PLAYGROUND.CS2_PIZZA_RUNNER.PIZZA_TOPPINGS - topping ID to name lookup
- TIL_PLAYGROUND.CS2_PIZZA_RUNNER.PIZZA_NAMES - pizza ID to name lookup
