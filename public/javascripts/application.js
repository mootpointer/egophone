$(document).ready(function(){
	$('menu > a').click(function(){
		$('.current').removeClass('current');
		$('#' + $(this).attr('rel')).addClass('current');
		$(this).addClass('current');
		return false;
	});
	
	$('.person').click(function(){
		$.ajax({
					url: '/persons/' + $(this).html().trim(), 
					dataType: 'json',
					success: function(json){	
						$('#stats').addClass('current');
						var history = new Array();
						var div = $('#personal-histogram').children('div:first');
						div.html('');
						$.each(json.time_of_day, function(hour){
							div.append('<p>' + hour + " : " + json.time_of_day[hour] + '</p>');
						});
						
						// div.tufteBar({
						// 	data: history
						// });
					}
				});
	})
});

function drawHistogram(data){
	$('#search-results-graph').tufteBar({
    data: data,
		color: '#FF5E99'
  });
}