jQuery.extend({
	activate: function(element) {
	    element = $(element);
	    element.focus();
	    if (element.select)
	      element.select();
	},
	indexOf: function(object, array) {
		for (var i = 0; i < array.length; i++)
			if (array[i] == object) return i;
		return -1;
	}
});

Jisho = function() {
	var pub = {};

	pub.initContext = function() {
		if( section == 'words' ) {
		    if( document.forms[0].japanese.value != "" ) {
	    		$.activate(document.forms[0].japanese);
	    	}
	    	else if( document.forms[0].japanese.value == "" && document.forms[0].translation.value == "") {
	    		$.activate(document.forms[0].japanese);
	    	}
	    	else {
	    		$.activate(document.forms[0].translation);
	    	}
	    	//displaySmartfmCount();
	    	linkWordDetails();
    	}
	    else if( section == 'kanji' ) {
		    if( document.forms[0].reading.value != "" ) {
	    		$.activate(document.forms[0].reading);
	    	}
	    	else if( document.forms[0].meaning.value != "" ) {
	    		$.activate(document.forms[0].meaning);
	    	}
	    	else if( document.forms[0].code.value != "" ) {
	    		$.activate(document.forms[0].code);
	    	}
	    	else {
	    		$.activate(document.forms[0].reading);
	    	}
	    }
	    else if( section == 'sentences' ) {
		    if( document.forms[0].japanese.value != "" ) {
	    		$.activate(document.forms[0].japanese);
	    	}
	    	else if( document.forms[0].japanese.value == "" && document.forms[0].translation.value == "") {
	    		$.activate(document.forms[0].japanese);
	    	}
	    	else {
	    		$.activate(document.forms[0].translation);
	    	}
	    }
	    else if( section == 'home' ) {
			if(  !document.forms[0].japanese.value
				&& !document.forms[0].translation.value
				&& !document.forms[1].reading.value
				&& !document.forms[1].meaning.value
				&& !document.forms[2].translation.value
				&& !document.forms[2].japanese.value
			)
			{
				$.activate(document.forms[0].japanese);
			}
		}
		else if( section == 'kanji_by_rad' ) {
			Radicals.activate();
			Radicals.activateSizer();
		}
	};
	
	displaySmartfmCount = function() {
	  url = "http://api.smart.fm/items/matching/" + $('#j_field').val() + '+' + $('#g_field').val() + ".json?callback=?&per_page=100&language=ja&translation_language=en&api_key=2pkmawpsk6dt4p5k353fyujx";
	  if ( $('#smartfm_dict_button').text() == 'Smart.fm (...)' ) {
      $.getJSON(url,
        function(data) {
          $('#smartfm_count').text(data.length);
        });
	  }
	};
	
	linkWordDetails = function() {
	  $('.representation').click(function(){
	    Jisho.detailsFor(this);
	  });
	  $('.reading_text').click(function(){
	    Jisho.detailsFor(this);
	  });
	  $('#details_box_area').bind('mouseleave', function(){
      $(this).hide();
	  });
	};
		
	pub.detailsFor = function(word) {
	  box = $("#details_box_area");
	  word = $(word);
	  box.css('top', word.position().top - 85 );
    box.css('left', word.position().left - 30);
    
    // Reading and representation
	  box.find(".details_main").text(word.text());
	  if ( word.hasClass("representation") ) {
  	  box.find(".details_sub").text(word.parent().parent().find(".reading_text").text());
	  }
	  else {
	    box.find(".details_sub").empty();
	  }
	  
	  // Local links
	  links = $(".details_links ul.local");
	  links.empty();
	  text = "<li><a href='/sentences/j="+word.text()+"'>Sentences</a>";
	  if ( word.hasClass("representation") ) {
	    text += ", <a href='/kanji/details/"+word.text()+"'>Kanji details</a>";
    }
	  links.append(text + "</li>");    
    
    // Actions
	  links = $(".details_links ul.actions");
	  links.empty();
	  links.append("<li><a href='#'>Save to Smart.fm</a></li>");
	  
	  // External links
	  links = $(".details_links ul.external");
	  links.empty()
	       .append("<li><a href='http://smart.fm/items/matching/"+word.text()+"'>Smart.fm search</a></li>");
	       .append("<li><a href='http://dictionary.goo.ne.jp/srch/all/"+word.text()+"/m0u'>Goo Jisho</a></li>");
	       .append("<li><a href='http://dic.yahoo.co.jp/bin/dsearch?stype=0&dtype=2&p="+sjis_for[word.text()]+"'>Yahoo Jisho</a></li>");
	       .append("<li><a href='http://www.google.com/search?ie=utf8&oe=utf8&lr=lang_ja&q="+word.text()+"'>Google</a></li>");
	       .append("<li><a href='http://images.google.com/images?hl=en&lr=&sa=N&tab=wi&q="+word.text()+"'>Google Image Search</a></li>");
	       .append("<li><a href='http://eow.alc.co.jp/"+word.text()+"'>Eijiro (ALC)</a></li>");
	       .append("<li><a href='http://www.jekai.org/cgi-jekai/siteindex/jsearch.pl?Q="+sjis_for[word.text()]+"'>JeKai</a></li>");
	       .append("<li><a href='http://www.jgram.org/pages/viewList.php?search.x=16&search.y=8&s="+sjis_for[word.text()]+"'>Jgram</a></li>");
	       .append("<li><a href='http://en.wiktionary.org/wiki/"+word.text()+"'>Wiktionary</a></li>");
	       .append("<li><a href='http://ja.wikipedia.org/wiki/"+word.text()+"'>Wikipedia (Japanese)</a></li>");
    
	  box.show();
	};
	
	/* http://www.alistapart.com/articles/hybrid/ */
	/* Fix hovering events in Explorer */
	pub.fixExplorer = function() {
		if( document.all && document.getElementById ) {
			var all_spans = document.getElementsByTagName("span");

			for( i = 0; i < all_spans.length; i++ ) {
				span = all_spans[i];

				if( span.className.indexOf("resources") != -1 ) {
					span.onmouseover = function() {
						this.className += " over";
					}

					span.onmouseout = function() {
						this.className = this.className.replace( " over", "");
					}
				}

				if( span.className.indexOf("advanced") != -1 ) {
					span.onmouseover = function() {
						this.className += " over";
					}

					span.onmouseout = function() {
						this.className = this.className.replace( " over", "");
					}
				}

				if( span.className.indexOf("kanji") != -1 ) {
					span.onmouseover = function() {
						this.className += " over_kanji";
					}

					span.onmouseout = function() {
						this.className = this.className.replace( " over_kanji", "");
					}
				}
			}

			var all_spans = document.getElementsByTagName("h1");

			for( i = 0; i < all_spans.length; i++ ) {
				span = all_spans[i];

				if( span.className.indexOf("literal") != -1 ) {
					span.onmouseover = function() {
						this.className += " over_literal";
					}

					span.onmouseout = function() {
						this.className = this.className.replace( " over_literal", "");
					}
				}
			}
		}
	};
	
	rand = function(n) {
	  return ( Math.floor ( Math.random ( ) * n + 1 ) );
	};
	
	return pub;
}();

Radicals = function() {
	var pub = {};
	var selected_radicals = new Array();
	var is_disabled_radical = new Array();
	var loading_radicals = false;
	
	pub.reset = function() {
		// Deselect selected radicals
		for ( radical in selected_radicals ) {
			if (radical.indexOf("rad") >= 0) {
				$('#' + radical).removeClass('selected_radical');
			}
		}	

		// Enable disabled radicals
		$('#radical_table .radical').removeClass('disabled_radical');

		// Empty the selected_radicals and is_disabled_radical hashes
		selected_radicals = {};
		is_disabled_radical = {};

		// Empty the found kanji
		$('#found_kanji').empty().append('<h2>No radicals selected</h2>');
	};
	
	pub.activate = function() {
		$('.radical').click(clickRadical);
	};
	
	clickRadical = function(event) {
		radical = event.target;

		// Fix so the IMG isn't the one modified, even if it sent the event	
		if (radical.tagName == 'IMG') {
			radical = radical.parentNode;
		}

		$(radical).toggleClass('selected_radical');

		// Deselect the radical if it already is selected
		if (selected_radicals[radical.id] && selected_radicals[radical.id][0] == 1) {
			selected_radicals[radical.id][0] = 0;
		}
		else {
			// Create the new span
			var new_id = "rand_" + rand(100) + "_" + radical.id;

			// Show and remember it
			selected_radicals[radical.id] = [1, new_id];
		}

		// Do the call
		getKanji();
	};
	
	getKanji = function() {
		// Build param string
		var params = "";
		
		for (radical in selected_radicals) {
			if (selected_radicals[radical][0] == 1) {
				params += "rad=" + encodeURIComponent(radical) + ';';
			}
		}

		// Do the AJAX stuff
		loading_radicals = true;
		
		$('#found_kanji').empty().append('<p id="loading">Searching for kanji, please wait ...</p>');
		
		$.ajax({
			type: 'GET',
			url: '/kanji/radicals/find/',
			dataType: 'json',
			data: params,
			complete: function() {
				loading_radicals = false;
			},
			success: function(data) {
				// Reset radicals if told to
				if ( data.reset ) {
					Radicals.reset();
					return;
				}
				
				// Header
				$('#found_kanji').empty().append("<h2>Found "+ data.count +" kanji <small>"+ data.notice +"</small></h2> <p class='clearfix' id='kanji_container'></p>");
				
				// Insert radicals
				$('#kanji_container').empty();
				current_strokes = 0;
				$.each(data.kanji, function(i, kanji){
					if ( current_strokes < kanji.strokes ) {
						$('#kanji_container').append('<span>'+ kanji.strokes +'</span>');
						current_strokes = kanji.strokes;
					}
					
					$('#kanji_container').append("<a href='/kanji/details/&#"+ kanji.ord +";' class='"+ kanji.grade +"'>&#"+ kanji.ord +';</a>');
				});
				
				// Validate radicals
				var all_elements = $('#radical_table .radical').get();
                $(all_elements).each(function(i, radical){
                    if ( data.is_valid_radical[radical.id] ) {
                        if ( is_disabled_radical[radical.id] ) {
                	        $(radical).removeClass('disabled_radical');
                	        is_disabled_radical[radical.id] = 0;
                	    }
                    }
                    else {
                        if ( !is_disabled_radical[radical.id] ) {
                	        $(radical).addClass('disabled_radical');
                	        is_disabled_radical[radical.id] = 1;
                	    }
                    }
                });
			}
		});
	};
	
	pub.activateSizer = function() {
	    var sizer = $('#radical_sizer');

	    if (radicals_are_expanded == 1) {
	        sizer.empty().append('Show fewer');
	    }
	    else {
	        sizer.empty().append('Show all');
	    }

	    sizer.click(resizeRadicals);
	};
	
	resizeRadicals = function() {
	    var radicals = $('#radicals');
	    var sizer = $('#radical_sizer');

	    var now = new Date();
	    now.setTime(now.getTime() + 157680000000); // 5 * 365 * 24 * 60 * 60 * 1000
	    var now_string = now.toGMTString();

	    if (radicals_are_expanded == 1) {
	        radicals.addClass('radicals_small');
	        sizer.empty().append('Show all');
	
	        document.cookie = 'radicals_are_expanded=0; expires=' + now_string;
	        radicals_are_expanded = 0;
	    }
	    else {
	        radicals.removeClass('radicals_small');
	        sizer.empty().append('Show fewer');
	
	        document.cookie = 'radicals_are_expanded=1; expires=' + now_string;
	        radicals_are_expanded = 1;
	    }
	};
	
	return pub;
}();

// Init page
$(document).ready(function() {
	Jisho.initContext();
});

// And for Explorer <= 6
if ( is_ie == 1 ) {
	Jisho.fixExplorer();
	ADxMenu_IESetup();
}