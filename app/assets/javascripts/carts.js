$(document).ready(function() {
    $('input[type=radio]').on('change', function() {
        if ($('#use_new').is(':checked')) {
            $('#new_card_cont').css('display', 'block');
            $('#saved_card_cont').css('display', 'none');
        } else if ($("#use_saved").is(':checked')) {
            $('#new_card_cont').css('display', 'none');
            $('#saved_card_cont').css('display', 'block');
        }
    });
    // explicitly trigger change event so that the selected inputs appear on refresh.
    $('#use_new').change();
});
