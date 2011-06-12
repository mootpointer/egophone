$(document).ready(function(){
	$('menu > a').click(function(){
		$('.current').removeClass('current');
		$('#' + $(this).attr('rel')).addClass('current');
		$(this).addClass('current');
		return false;
	});
	
	$('.person').click(function(){
		// $.ajax({
		// 		url: '/persons/' + $(this).html().trim(), 
		// 		dataType: 'json',
		// 		success: function(json){	
		// 			$('#stats').addClass('current');
		// 			$('#personal-histogram').html('');
		// 			$.each(json.time_of_day, function(count){
		// 				$('#personal-histogram').append(count);
		// 			});
		// 		}
		// 	});
	})
});

function drawHistogram(data){
	$('#search-results-graph').tufteBar({
    data: data,
		color: '#FF5E99'
  });
}