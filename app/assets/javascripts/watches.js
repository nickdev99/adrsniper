$(document).ready(function() {
    if ($(document).find("#watch_search_end_date").length <= 0) {
        //console.log("Not the watches page, not executing watches page code.");
        return true;
    }
    // register jquery-ui datepicker on jqdp classes.
    $('.jqdp').datepicker({dateFormat: "MM d, yy", onClose: notify_prefs_visible, minDate: moment().toDate()});
    // register new notify range box on button click.
    $('#new_notify_range').click(function(ev){ create_new_notify_range(null, null)  });
    // register destroy notify range on button click.
    $('.remove_notify_range').click(function(ev) { destroy_notify_range_by_id($(ev.target).attr("data-range-id"));  })
    // trigger watch paragraph visibility manually on initial load.
    notify_prefs_visible(null);
    load_extant_notify_ranges(null);
    //refurb_dates = load_refurbishment_dates($("#watch_restaurant_id").val());
    //disable_refurb_dates(refurb_dates);
    $("form").on('submit', function (ev) {
        date_fields = $(ev.target).find(".hasDatepicker");
        date_fields.each( function(i,el) { $(el).val(convert_friendly_words_to_datestamp($((el).val()))); });
    });
    $(".hasDatepicker").each( function(i,el) { $(el).val(convert_datestamp_to_friendly_words($(el).val()));  });
    $("#watch_restaurant_id").change( function (ev) {
        var a = $("#watch_restaurant_id").val();
        load_refurbishment_dates(a)
    });
    load_refurbishment_dates($("#watch_restaurant_id").val());

    $("#event-timestamps-button").click(function () {load_event_timestamps($("#event_watch_event_id").val(), $("#search_start_date").val(), $("#search_end_date").val())})

});

function convert_datestamp_to_friendly_words(datestamp) {
    if (datestamp.length > 0) {
        return dateize_string(datestamp).format("MMMM D, YYYY");
    } else {
        return "";
    }
}

function convert_friendly_words_to_datestamp(friendly_words) {
    if (friendly_words.length > 0) {
        return dateize_string(friendly_words).format("GGGG-MM-DD");
    } else {
        return "";
    }
}


function load_refurbishment_dates(id) {
    $.ajax({
        url: '/refurbishments/get_dates/' + id,
        dataType: 'json',
        success: function(xhr) {
            bad_date_arr = xhr;
            if (xhr.length > 0) {
                $('.jqdp').datepicker("option", "beforeShowDay", function(date) {
                    var dateString = $.datepicker.formatDate('yy-mm-dd', date);
                    return [bad_date_arr.indexOf(dateString) == -1];
                });
            }
        }
    });
}

function load_event_timestamps(id, range_start, range_end) {
    $.ajax({
        url: '/watches/show_event_timestamps/' + id,
        dataType: 'json',
        type: 'POST',
        data: {search_start_date: range_start, search_end_date: range_end},
        success: function(xhr) {
            if (xhr.length > 0) {
                console.log(xhr)
            }
        }
    });
}

function check_filled_in_dates() {
    if ($("#watch_search_end_date").val().length > 0) {
        if ($("#watch_search_start_date").val().length > 0) {
            return true;
        }
    }
    return false;
}

function dateize_string(str) {
     return moment.tz(str, "America/New_York");
}

function apply_date_rules(ev) {
    if ($("#watch_search_start_date").val().length > 0) {
        var mobj = dateize_string($('#watch_search_start_date').val());
        // there is a bug in datepicker where setting minDate blanks the value
        // even if the minDate is in range. Therefore, we manually save the
        // value out of watch_search_end_date before setting any options, and
        // then we restore it when we're done.
        var end_val = $("#watch_search_end_date").val();
        $("#watch_search_end_date").datepicker("option", "minDate", mobj.toDate());
        $("#watch_search_end_date").datepicker("option", "maxDate", mobj.add('d', 9).toDate());
        $("#watch_search_end_date").val(end_val);
    }
}

function notify_prefs_visible(ev) {
    filled_in = check_filled_in_dates();
    if (filled_in) {
        $("#mark_dates_first").hide();
        $("#dates_marked").show();
        past_adr_date_notify();
    } else {
        $("#date_notify_holder").empty();
        $("#dates_marked").hide();
        $("#mark_dates_first").show();
    }
    apply_date_rules(null);
    return true;
}

function past_adr_date_notify() {
    if (past_adr_date(moment.tz($('#watch_search_start_date').val(), "America/New_York")) ||
        past_adr_date(moment.tz($('#watch_search_end_date').val(), "America/New_York"))) {
        $('#past_adr_date_warning').show();
    } else {
        $('#past_adr_date_warning').hide();
    }
}

function past_adr_date(mtz) {
    if (Math.abs(mtz.diff(moment.tz(moment(), "America/New_York"), 'days')) > 180) {
        return true
    } else {
        return false
    }
}

var date_notify_counter = 0;

function load_extant_notify_ranges(ev) {
    var npj = $("#npj").val();
    if (npj.length > 0) {
        var times_list = $.parseJSON(npj);
        times_list.forEach(
            function(notify) {
               create_new_notify_range(null, notify);
            }
        );
    }
}

function check_time_range(count_string) {
    m_start = dateize_string(moment().format("LL") + " " + $("#date_notify_range_"+count_string+"_timepicker_start").val());
    m_end = dateize_string(moment().format("LL") + " " + $("#date_notify_range_"+count_string+"_timepicker_end").val());
    if (m_start.isSame(m_end) || m_end < m_start) {
        $("#date_notify_range_"+count_string+"_not_long_enough_msg").show();
    } else {
        $("#date_notify_range_"+count_string+"_not_long_enough_msg").hide();
    }
}

function create_new_notify_range(ev, notify) {
    date_notify_counter++;
    var count_string = date_notify_counter.toString();

    var startDate = null;
    var endDate = null;
    var sel_date = null;

    var notify_populated = $.isEmptyObject(notify) ? false : true;

    var startDate = dateize_string($("#watch_search_start_date").val());
    var endDate = dateize_string($("#watch_search_end_date").val());

    var templ = $("#date_notify_template").clone(true, true);
    var sel_box = templ.find("#date_notify_template_date_dropdown");
    var range_start_box = templ.find("#date_notify_template_timepicker_start");
    var range_end_box = templ.find("#date_notify_template_timepicker_end");

    var d = startDate;
    while (d <= endDate) {
        $("<option />").val(d.format("LL")).text(d.format("LL")).appendTo(sel_box);
        d = d.add('d', 1);
    }

    templ.find('.timepicker').pickatime({onRender: function() { setTimeout(function() { check_time_range(count_string)}, 10); }, onClose: function() { check_time_range(count_string); } });

    if (notify_populated) {
        sel_date = moment.tz(notify["date"], "America/New_York");
        sel_box.val(sel_date.format("LL"));
        range_start_box.val(dateize_string(notify["start_notify"]).format("LT"));
        range_end_box.val(dateize_string(notify["end_notify"]).format("LT"));
    }

    var repl_attrs = templ.find('[id*="_template_"]');
    repl_attrs.push(templ);
    $.each(repl_attrs,
        function (i,v) {
            $(v).attr("name", $(v).attr("id").replace("_template", "_range_"+count_string));
            $(v).attr("id", $(v).attr("id").replace("_template", "_range_"+count_string));
            if ($(v).attr("data-range-id") != null) {
                $(v).attr("data-range-id", count_string);
            }
        }
    );

    templ.css("display", "block");
    templ.appendTo("#date_notify_holder");
    return true;
}

function destroy_notify_range_by_id(range_id) {
    $("#date_notify_range_"+range_id).remove();
}
