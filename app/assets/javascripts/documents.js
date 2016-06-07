$(document).ready( function() {
  // register datepicker
  $('.jqdp').datepicker({dateFormat: "MM d, yy", minDate: moment().toDate()});

  // toggle display based on agreement
  $('#terms_accepted').change(function () {
     $('#pending_acceptance').toggle(this.checked);
  }).change(); //ensure visible state matches initially
});
