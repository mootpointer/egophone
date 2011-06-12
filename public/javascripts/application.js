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
						var hour = 0;
						$.each(json.time_of_day, function(count){
							div.append('<p>' + hour + " : " + count + '</p>');
							hour += 1;
							history.push([count, {}]);
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