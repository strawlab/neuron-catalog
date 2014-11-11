window.get_sort_key = (collection_name) ->
  if collection_name is "DriverLines"
    sort_key = 'name'
  else if collection_name is "NeuronTypes"
    sort_key = 'name'
  else if collection_name is "Neuropils"
    sort_key = 'name'
  else
    sort_key = '_id'
  sort_key
