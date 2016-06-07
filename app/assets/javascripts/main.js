jQuery(document).ready(function ($) {
	"use strict";
	
	function fullScreenBanner(){
		var fullSection = $('.full-screen-banner'),
		topHeader 		= $('.top-header'),
		bannerHeight	= $(window).height()-topHeader.height();
		fullSection.css('height',bannerHeight+'px');
	}
	fullScreenBanner();
	$(window).resize(function(){
		fullScreenBanner();
	});
	
	
	
	$('.image-carousel').flexslider({
		animation: "slide",
		animationLoop: false,
		controlNav: true,
		smoothHeight: true
	});
	
});	