Meteor.methods({
  get_specializations: function () {
    var x = Meteor.settings.NeuronCatalogSpecializations;
    if (typeof x !== "undefined" && x !== null) {
      return x;
    } else {
      return [];
    }
  }
});
