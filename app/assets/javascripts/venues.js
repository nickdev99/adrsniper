$(function(){
});

$(window).load(function() {
    var dine_search = function(date_range_start, date_range_end, meal_time, party_size, area) {
        var basic_url = '/dine-search.json';
        var url = basic_url + '?date_range_start=' + date_range_start + '&date_range_end=' + date_range_end
            + '&meal_time=' + meal_time +  '&party_size=' + party_size + '&area=' + area;

        $('#load').show();
        $.get(url, function( data ) {
            $('#load').hide();
            $('#dine_content').html(data);
        });
    };

    var get_dine = function() {
        var date_range_start = $('#date_range_start').val();
        var date_range_end = $('#date_range_end').val();
        var meal_time = $('#meal_time').val();
        var party_size = $('#party_size').val();
        var area = $('#area').val() || '';
        // validate
        if( date_range_start != '' && date_range_end != '' && meal_time != '' && party_size != '' ) {
            dine_search(date_range_start, date_range_end, meal_time, party_size, area);
        }
    };

    // call submit automatically when parameters valid

    $('#dine-form').submit(function (){
        get_dine();

        return false;
    });

    get_dine();
});