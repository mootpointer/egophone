$(document).ready(function(){
	$('menu > a').click(function(){
		$('.current').removeClass('current');
		$('#' + $(this).attr('rel')).addClass('current');
		$(this).addClass('current');
		return false;
	});
	
});

function drawHistogram(data){
	$('#search-results-graph').tufteBar({
    data: data
  });
}