# minDiff 0.01-3

- `create_groups` now has a parameter `talk` controlling whether the
  function prints out its progress
- `create_groups` now has a parameter `exact`. If set to `TRUE` (default
  is `FALSE`) all possible group assignments are tested. The number of
  possible assignment grows exponentially with the input size, using
  this option is therefore only recommended for small sets of items
  (maybe < 20; number of possible assignments grows even faster with
  item number when more sets are considered)
- Default value of parameter `repetitions` in `create_groups` now is 100
- added function `next_permutation` that is used to create all item
  assignments in `create_groups`

# minDiff 0.01-2

- renamed `createGroups` to `create_groups`
- parameter `write_file` in `create_groups` now defaults to `FALSE`
- Some changes to the documentation in `?create_groups`

