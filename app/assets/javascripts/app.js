var WDW = {};

WDW.gui = {};
WDW.config = {};

// when document is loaded
$(function() {

	var isAndroid = /android/i.test(navigator.userAgent.toLowerCase());
 
	if (isAndroid) {
		$("body").addClass("android");
	}

	if($.browser.mobile) {
		$("body").addClass("touch");
	}

	WDW.gui.initSelect();
	WDW.gui.initDatepicker();
	WDW.gui.initPopover();
	WDW.gui.initTooltip();
	WDW.gui.initArcText();
	WDW.gui.initCarousel();
	WDW.gui.initAffix();

	WDW.gui.initSearchBox();
	WDW.gui.initSidebar();

	WDW.gui.initTestimonials();
});


WDW.gui.initPopover = function() {
	var $popover = $('#watchesPopover'),
		$watches = $popover.closest('.watches'),
		contentSelector = $popover.data('inner');

	$popover.popover({
		container: $watches,
		html: true,
		template: '<div class="popover watches-popover-container" role="tooltip"><div class="arrow"></div><div class="popover-content"></div></div>',
		content: $(contentSelector).html()
	});

	$popover.on('show.bs.popover hide.bs.popover', function() {
		$watches.toggleClass('open');
	});

	$(".watches a").on('click', function(e) {
		e.preventDefault();
		$popover.popover('toggle');
	});
};

WDW.gui.initArcText = function() {
	var $text = $('.arc-text');
	var radius = $text.data('radius') || 0;
	
	$text.arctext({radius: radius});
};

WDW.gui.initCarousel = function() {
	var $container = $('#header-carousel'),
		$carousel = $container.find('.carousel'),
		$prevArrow = $container.find('.arrow.left'),
		$nextArrow =$container.find('.arrow.right');
	
	$carousel.slick({
		prevArrow: $prevArrow,
		nextArrow: $nextArrow,
		infinite: true,
		speed: 250,
		autoplay: true,
		swipe: false,
		pauseOnHover: false,
		touchMove: false,
		autoplaySpeed: 10000
	});
};

WDW.gui.initSelect = function() {
	$('.selectpicker').selectpicker();
};

WDW.gui.initDatepicker = function() {
	var $datepicker = $('.datepicker');
	$('.datepicker').datepicker({
		showButtonPanel: true,
		showOtherMonths: true,
		firstDay: 1
    });

	var dayNamesShort = $datepicker.datepicker('option', 'dayNamesShort');
	$datepicker.datepicker('option', 'dayNamesMin', dayNamesShort);
};

WDW.gui.initSearchBox = function() {
	var $input = $('.restaurant-input');
	$('.toggle-restaurant-input').on('click', function(e) {
		e.preventDefault();
		$input.toggle();

		// disable input on hide, and enable on show
		var dom = $input.get(0);
		dom.disabled = !dom.disabled;
	});
};

WDW.gui.initTooltip = function() {
	$('[data-toggle="tooltip"]').tooltip({
		container: 'body'
	});
};

WDW.gui.initAffix = function() {
	var $fixed = $('#affix');
	var $subNav = $('.sub-navigation');

	if ($fixed.length) {
		var top = $subNav.length ? $subNav.offset().top : $fixed.offset().top - 30;
		var diff = $subNav.length ? $fixed.offset().top - top : false;

		$fixed.affix({
			offset: {
				top: top
			}
		});
		
		if (diff) {		
			$fixed.on('affix.bs.affix', function() {
				$fixed.css('top', diff);
			});
		}
	}

	if ($subNav.length) {
		var top = $subNav.offset().top;
		var height = $subNav.height();
		var $prev = $subNav.prev();
		var initialMargin = $prev.css('margin-bottom');
		$subNav.affix({
			offset: {
				top: top
			}
		});

		$subNav.on('affix.bs.affix', function() {
			$prev.css('margin-bottom', height);
		});

		$subNav.on('affix-top.bs.affix', function() {
			$prev.css('margin-bottom', initialMargin);
		});

		$('body').scrollspy({
			target: '.sub-navigation',
			offset: $subNav.height() + 20
		});

		$subNav.find('a').on('click', function(e) {
			var id = $(this).attr('href');

			if (id[0] == '#') {
				e.preventDefault();

				if (id.length > 1) {				
					var distance = $(id).offset().top - $subNav.height() - 10;
					var duration = (distance <= 400) ? 100 : distance / 4;

					// scroll to element
					$('html, body').animate({
						scrollTop: distance
					}, duration);
				}
			}
		});
	}
};

WDW.gui.initSidebar = function() {
	var $container = $('.move-to-left'),
		$sidebar = $('.sidebar-container > div');

	$('.toggle-sidebar').on('click', function() {
		$container.toggleClass('move-to-left');
		$sidebar.toggleClass('hide-sidebar');
	});
};

WDW.gui.initTestimonials = function() {

	var $slider = $('.testimonials-slider');

	if ($slider.length) {
		var settings = {
			slidesToShow: 3,
			slidesToScroll: 1,
			centerMode: true,
			focusOnSelect: true,

			accessibility: false,
			speed: 200,
			arrows: false,
			draggable: false,
			swipe: false,
			touchMove: false,

			responsive: [
				{
					breakpoint: 992,
					settings: 'unslick'
				}
			]
		}; 

		$slider.slick(settings);

		$(window).resize(function() {
			if ($(window).width() >= 992 && !$slider.hasClass('slick-initialized')) {
				
				$slider.slick(settings);
			}
		});

		$('.testimonials-slider').on('beforeChange', function() {
			$('.testimonials-container .wrapper').removeClass('open');
		});

		$('.testimonials-slider').on('afterChange', function() {
			$('.testimonials-container .slick-center.wrapper').addClass('open');
		});
	}
};

