$(document).ready(function(){
	$('menu > a').click(function(){
		$('.current').removeClass('current');
		$('#' + $(this).attr('rel')).addClass('current');
		$(this).addClass('current');
		return false;
	});
	
});