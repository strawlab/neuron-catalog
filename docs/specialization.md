## Specializations

The neuron-catalog support specializations in which resources
applicable to only a particular database instance, such as databases
for a particular model organism, can be utilized. Currently,
specializations exist for Drosophila melanogaster.

### Drosophila melanogaster specializations

By placing the string `"Drosophila melanogaster"` in your
[settings](settings.md), you enable several piecies of code:

- detection of VT (Vienna Tile) lines. If a VT line is detected, links
  are generated to BrainBaseWeb and the VDRC databases.

- detection of FlyLight lines. If a FlyLight line is detected, a
  button is made that will query the FlyLight database at Janelia.

- FlyCircuit.tw idid links. Neuron types can be associated with
  specific idid values at FlyCircuit.tw.
