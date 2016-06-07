$(document).ready(function() {
    // register jquery-ui datepicker on jqdp classes.
    $('.jqdp').datepicker({dateFormat: "MM d, yy", onClose: activate_countdown, minDate: moment().toDate()});
    activate_countdown();
});

var to_lock = {}

function set_countdown_text(jq_sel, cdjs_obj) {
    if (cdjs_obj.value > 0) {
        $(jq_sel).text(cdjs_obj.toString());
    } else {
        $(jq_sel).text('Done!');
    }
}

var ivals = []

function activate_countdown() {

    while (ivals.length > 0) { ivals.pop();  }

    cded_val = $('#countdown_end_date').val();
    if (!cded_val) { return; }

    end_date = moment(cded_val);
    ivals.push(countdown(function(ts) { set_countdown_text('#arrival-text', ts) }, end_date.toDate(), ~(countdown.MILLISECONDS)));
    ivals.push(countdown(function(ts) { set_countdown_text('#dvc-home-text', ts) }, (end_date.clone().subtract('months', 11).toDate()), ~(countdown.MILLISECONDS)));
    ivals.push(countdown(function(ts) { set_countdown_text('#dvc-away-text', ts) }, (end_date.clone().subtract('months', 7).toDate()), ~(countdown.MILLISECONDS)));
    ivals.push(countdown(function(ts) { set_countdown_text('#adr-text', ts) }, (end_date.clone().subtract('days', 180).toDate()), ~(countdown.MILLISECONDS)));
    ivals.push(countdown(function(ts) { set_countdown_text('#fpp-text', ts) }, (end_date.clone().subtract('days', 60).toDate()), ~(countdown.MILLISECONDS)));
}
