iPhone = function() {
	var pub = {};
	
	pub.currentPage = '';
	
	pub.hideSafariChrome = function() {
	    window.scrollTo(0, 1);
	};
	
	pub.doWordSearchForPage = function(page) {
	    // Build params string
        params = 'flavour=iphone;romaji=' + $('#words_s_romaji').get(0).value + ';common=' + $('#words_s_common').get(0).value + ';dict=' + $('#words_s_dict').get(0).value + ';jap=' + $('#words_s_ja').get(0).value + ';eng=' + $('#words_s_en').get(0).value + ';page=' + page;
        
        $.ajax({
            url: '/words/',
            dataType: 'json',
            data: params,
            error: function (XMLHttpRequest, textStatus, errorThrown) {
                $('#words .status').text('Error: ' + textStatus);
            },
            success: function(data, textStatus) {
                pub.drawWordResults(data);
            }
         });
	};
	
	pub.doKanjiSearchForPage = function(page) {
	    // Build params string
        params = 'flavour=iphone;jy_only=' + $('#kanji_s_jy').get(0).value + ';rt=jap;reading=' + $('#kanji_s_reading').get(0).value + ';mt=en;meaning=' + $('#kanji_s_meaning').get(0).value + ';page=' + page;
        
        $.ajax({
            url: '/kanji/',
            dataType: 'json',
            data: params,
            error: function (XMLHttpRequest, textStatus, errorThrown) {
                $('#kanji .status').text('Error: ' + textStatus);
            },
            success: function(data, textStatus) {
                if ( data.type == 'kanji' ) {
                    pub.drawKanjiResults(data);
                }
                else {
                    pub.drawKanjiDetails(data);
                }
            }
         });
	};
	
	pub.doSentenceSearchForPage = function(page) {
	    // Build params string
        params = params = 'flavour=iphone;jap=' + $('#sentences_s_ja').get(0).value + ';eng=' + $('#sentences_s_en').get(0).value + ';page=' + page;
        
        $.ajax({
            url: '/sentences/',
            dataType: 'json',
            data: params,
            error: function (XMLHttpRequest, textStatus, errorThrown) {
                $('#sentences .status').text('Error: ' + textStatus);
            },
            success: function(data, textStatus) {
                pub.drawSentenceResults(data);
            }
         });
	};
	
	pub.drawSentenceResults = function(data) {
	    result_ul = $('#sentences_result_ul').get(0);
        
        if ( data.pager.current_page == 1 )
            $(result_ul).empty();

        if ( data.total == 0 ) {
            $('#sentences .status').text('Found 0 sentences.');
        }
        else {
            if ( data.pager.current_page == 1 ) {
                status_text = 'Found ' + data.total + (data.total == 1 ? ' sentence.' : ' sentences.');
                $('#sentences .status').text( status_text );
                $(result_ul).show();
            }
            else {
                $('#sentences_more_link').remove();
            }
            
            lis = ''; // Container for the <li>:s we will later put on the page
            
            $.each(data.sentences, function(i, sentence){
                // Put it on the page
                lis = lis
                    + '<li>'
                    + '<div class="japanese">' + sentence.japanese + '</div>'
                    + '<div class="english">' + sentence.english + '</div>'
                    + (sentence.tag ? '<div class="tags">' + sentence.tag + '</div>' : '' )
                    + '<div class="links">'
                    + '<a href="#kanji" onClick="iPhone.doRelatedSearch(\'kanji\',\'' + sentence.key + '\');">Kanji details</a>'
                    + '</div>'
                    + '</li>';
            });
            
            if ( data.pager.current_page < data.pager.last_page ) {
                lis = lis + '<li id="sentences_more_link" class="more_link"><a href="#sentences" onClick="$(\'#sentences_more_link\').html(\'<span>Loading ...</span>\'); iPhone.doSentenceSearchForPage(' + (data.pager.current_page + 1) + '); return false;">Load more</a></li>';
            }
            
            //startTime = new Date().getTime();
            $(result_ul).get(0).innerHTML = $(result_ul).get(0).innerHTML + lis;
            //endTime = new Date().getTime();
            //alert('Elapsed: ' + (endTime - startTime));
        }
	};
	
	pub.drawWordResults = function(data) {
	    result_ul = $('#words_result_ul').get(0);
        
        if ( data.pager.current_page == 1 )
            $(result_ul).empty();

        if ( data.total == 0 ) {
            $('#words .status').text('Found 0 words.');
        }
        else {
            if ( data.pager.current_page == 1 ) {
                status_text = 'Found ' + data.total + (data.total == 1 ? ' word.' : ' words.');
                $('#words .status').text( status_text );
                $(result_ul).show();
            }
            else {
                $('#words_more_link').remove();
            }
            
            lis = ''; // Container for the <li>:s we will later put on the page
            
            $.each(data.words, function(i, word){
                // Make readings
                reading = (word.kanji ? '<span class="kanji">' + word.kanji + '</span> ・ ' + word.kana : word.kana);

                // Make tags
                tags = word.is_common == 1 ? '<span class="common">Common word, </span>' : '';
                if ( word.tags.length > 0 ) {
                  tags = tags + word.tags[0].expanded;
                }
                for(i = 1; i < word.tags.length; i++) {
                    tags = tags + ', ' + word.tags[i].expanded;
                }

                // Make meanings
                if ( word.meanings.length == 1 ) {
                    meanings = word.meanings[0];
                }
                else {
                    meanings = '<ol>';
                    for(i = 0; i < word.meanings.length; i++) {
                        meanings = meanings + '<li>' + word.meanings[i] + '</li>';
                    }
                    meanings = meanings + '</ol>';
                }

                // Make kanji details link
                if ( word.kanji ) {
                    kanjiLink = ', <a href="#kanji" onClick="iPhone.doRelatedSearch(\'kanji\',\''
                        + word.kanji + '\');">Kanji details</a>';
                }
                else {
                    kanjiLink = '';
                    //kanjiLink = '<span class="disabled">Kanji details</span>';
                }

                // Put it on the page
                lis = lis
                    + '<li>'
                    + reading
                    + '<div class="tags">'
                    + tags
                    + '</div>'
                    + meanings
                    + '<div class="links"><a href="#sentences" onClick="iPhone.doRelatedSearch(\'sentences\',\''
                    + word.key
                    + '\');">Sentences</a>'
                    + kanjiLink
                    + '</div>'
                    + '</li>';
            });
            
            if ( data.pager.current_page < data.pager.last_page ) {
                lis = lis + '<li id="words_more_link" class="more_link"><a href="#words" onClick="$(\'#words_more_link\').html(\'<span>Loading ...</span>\'); iPhone.doWordSearchForPage(' + (data.pager.current_page + 1) + '); return false;">Load more</a></li>';
            }
            
            //startTime = new Date().getTime();
            $(result_ul).get(0).innerHTML = $(result_ul).get(0).innerHTML + lis;
            //endTime = new Date().getTime();
            //alert('Elapsed: ' + (endTime - startTime));
        }
	};
	
	pub.drawKanjiDetails = function(data) {
	    result_ul = $('#kanji_result_ul').get(0);
	    $(result_ul).addClass('details');

        $(result_ul).empty();
        
        if ( data.total == 0 ) {
            $('#kanji .status').text('Found 0 kanji.');
        }
        else {
            jumps = ''; // Intra-page jump links
            lis = ''; // Container for the <li>:s we will later put on the page
            
            $.each(data.kanji, function(i, kanji) {
                jumps = jumps + '<a href="#kanji_' + kanji.id + '">' + kanji.literal + '</a> ';
                
                // Make readings
                ons = new Array();
                kuns = new Array();
                $.each(kanji.readings, function(i, reading) {
                    url_start = '<a href="#words" onClick="iPhone.doRelatedSearch(\'words\',\'' + kanji.literal + '　';
                    url_middle = '\');">';
                    url_end = '</a>';
                    current = url_start + reading.normalized + url_middle + reading.reading + url_end;
                    
                    switch ( reading.r_type ) {
                        case 'ja_on':
                            ons.push(current);
                            break;
                        case 'ja_kun':
                            kuns.push(current);
                            break;
                    }
                });
                readings_ja_on = ons.length > 0 ? ons.join('; &#160; ') : '';
                readings_ja_kun = kuns.length > 0 ? kuns.join('; &#160; ') : '';
                readings_ja_nanori = kanji.nanoris ? kanji.nanoris.join('; &#160; ') : '';

                // Make tags
                tags = (kanji.grade >= 1 && kanji.grade <= 8) ? '<span class="common">Jouyou kanji, </span>' : '';
                tags = tags + kanji.strokes.join(', ') + ' strokes';

                // Make specs
                switch ( kanji.grade ) {
                    case '8':
                        specs = '<strong>Jouyou</strong> kanji taught in junior high';
                        break;
                    case '9':
                        specs = '<strong>Jinmeiyou</strong> kanji used in names';
                        break;
                    case '1':
                    case '2':
                    case '3':
                    case '4':
                    case '5':
                    case '6':
                        specs = 'Taught in <strong>grade ' + kanji.grade + '</strong>';
                        break;
                    default:
                        specs = 'Not a general use character';
                }
                
                if ( kanji.frequencies ) {
                    specs = specs + '<br /> <strong>' + kanji.frequencies.join(', ') + '</strong> of 2500 most common kanji';
                }
                else {
                    specs = specs + '<br /> Not one of 2500 most common kanji';
                }

                // Make meanings
                meanings_en = kanji.meanings_en ? kanji.meanings_en.join('; &#160; ') : '';
                meanings_es = kanji.meanings_es ? kanji.meanings_es.join('; &#160; ') : '';
                meanings_pt = kanji.meanings_pt ? kanji.meanings_pt.join('; &#160; ') : '';

                // Make radicals
                radicals = '';
                $.each(kanji.radicals, function(i, radical) {
                    if ( radical.rad_type == 'classical' ) {
                        radicals = radicals + radical.glyph + ' (KanXi: ' + radical.rad_value;
                    }
                    else {
                        radicals = radicals + ', Nelson: ' + radical.rad_value;
                    }
                });
                radicals = radicals + ')';

                // Make parts
                parts = kanji.parts ? kanji.parts.join(', &#160; ') : '';
                
                // Make variants
                variants = kanji.variants ? kanji.variants.join('') : '';

                // Make SKIP codes
                skips = kanji.skip_codes ? kanji.skip_codes.join(', ') : '';

                // Make Unicode value
                unicodes = kanji.unicodes ? kanji.unicodes.join(', ') : '';

                // Put it on the page
                lis = lis
                    + '<li>'
                    + '<a name="#kanji_' + kanji.id + '"></a>'
                    + '<div class="kanji">' + kanji.literal + '</div>'
                    + '<div class="rest">'
                    + '<div class="tags">' + tags + '</div>'
                    + '<div class="tags">' + specs + '</div>'
                    + (readings_ja_on ? '<div class="readings"><div class="title">On </div><div class="value">' + readings_ja_on + '</div></div>' : '')
                    + (readings_ja_kun ? '<div class="readings"><div class="title">Kun </div><div class="value">' + readings_ja_kun + '</div></div>' : '')
                    + (readings_ja_nanori ? '<div class="readings"><div class="title">Nanori </div><div class="value">' + readings_ja_nanori + '</div></div>' : '')
                    + '<p>'
                    + (meanings_en ? '<div class="meanings"><div class="title">English </div><div class="value">' + meanings_en + '</div></div>' : '')
                    + (meanings_es ? '<div class="meanings"><div class="title">Spanish </div><div class="value">' + meanings_es + '</div></div>' : '')
                    + (meanings_pt ? '<div class="meanings portuguese"><div class="title">Portuguese </div><div class="value">' + meanings_pt + '</div></div>' : '')
                    + '</p>'
                    + (radicals ? '<div class="title">Radical </div><div class="value">' + radicals + '</div>' : '')
                    + (parts ? '<div class="title">Parts </div><div class="value">' + parts + '</div>' : '')
                    + (variants ? '<div class="title">Variants </div><div class="value"><a href="#kanji" onClick="iPhone.doRelatedSearch(\'kanji\',\'' + variants + '\');">' + variants + '</a></div>' : '')
                    + (skips ? '<div class="title">SKIP </div><div class="value">' + skips + '</div>' : '')
                    + (unicodes ? '<div class="title">Unicode </div><div class="value">' + unicodes + '</div>' : '')
                    + '<div class="links"><div class="value">'
                    + '<a href="#words" onClick="iPhone.doRelatedSearch(\'words\',\'' + kanji.literal + '\');">Words <strong>beginning with</strong> ' + kanji.literal + '</a><br />'
                    + '<a href="#words" onClick="iPhone.doRelatedSearch(\'words\',\'*' + kanji.literal + '*\');">Words <strong>containing</strong> ' + kanji.literal + '</a><br />'
                    + '<a href="#words" onClick="iPhone.doRelatedSearch(\'words\',\'' + kanji.literal + '*\');">Words <strong>ending with</strong> ' + kanji.literal + '</a><br />'
                    + '<a href="#sentences" onClick="iPhone.doRelatedSearch(\'sentences\',\'' + kanji.literal + '\');">Sentences containing ' + kanji.literal + '</a>'
                    + '</div></div>'
                    + '</div>'
                    + '</li>';
            });
            
            status_text = 'Found details for these kanji: ' + jumps;
            $('#kanji .status').html( status_text );
            $(result_ul).get(0).innerHTML = $(result_ul).get(0).innerHTML + lis;
            $(result_ul).show();
        }
	};
	
	pub.drawKanjiResults = function(data) {
	    result_ul = $('#kanji_result_ul').get(0);
	    $(result_ul).removeClass('details');

        if ( data.pager.current_page == 1 )
            $(result_ul).empty();
        
        if ( data.total == 0 ) {
            $('#kanji .status').text('Found 0 kanji.');
        }
        else {
            if ( data.pager.current_page == 1 ) {
                status_text = 'Found ' + data.total + ' kanji.';
                $('#kanji .status').text( status_text );
                $(result_ul).show();
            }
            else {
                $('#kanji_more_link').remove();
            }
            
            lis = ''; // Container for the <li>:s we will later put on the page
            
            $.each(data.kanji, function(i, kanji){
                // Make readings
                reading = kanji.readings ? kanji.readings.join('; &#160; ') : '';

                // Make tags
                tags = (kanji.grade >= 1 && kanji.grade <= 8) ? '<span class="common">Jouyou kanji, </span>' : '';
                tags = tags + kanji.strokes.join(', ') + ' strokes';

                // Make meanings
                meanings = kanji.meanings ? kanji.meanings.join('; &#160; ') : '';

                // Put it on the page
                lis = lis
                    + '<li>'
                    + '<div class="kanji">' + kanji.literal + '</div>'
                    + '<div class="rest">'
                    + '<span class="readings">' + reading + '</span>'
                    + '<div class="tags">' + tags + '</div>'
                    + '<span class="meanings">' + meanings + '</span>'
                    + '<div class="links">'
                    + '<a href="#kanji" onClick="iPhone.doRelatedSearch(\'kanji\',\'' + kanji.literal + '\');">Details</a>, '
                    + '<a href="#words" onClick="iPhone.doRelatedSearch(\'words\',\'*' + kanji.literal + '*\');">Words</a>, '
                    + '<a href="#sentences" onClick="iPhone.doRelatedSearch(\'sentences\',\'' + kanji.literal + '\');">Sentences</a>'
                    + '</div>'
                    + '</div>'
                    + '</li>';
            });
            
            if ( data.pager.current_page < data.pager.last_page ) {
                lis = lis + '<li id="kanji_more_link" class="more_link"><a href="#kanji" onClick="$(\'#kanji_more_link\').html(\'<span>Loading ...</span>\'); iPhone.doKanjiSearchForPage(' + (data.pager.current_page + 1) + '); return false;">Load more</a></li>';
            }
            
            $(result_ul).get(0).innerHTML = $(result_ul).get(0).innerHTML + lis;
        }
	};
	
	pub.doRelatedSearch = function(page, query) {
	    pub.clearFormForPage(page);
	    pub.activatePage(page);

	    switch ( page ) {
	        case 'words':
	            $('#words_s_ja').get(0).value = query;
    	        $('#words_form').submit();
	            break;
	        case 'kanji':
	            $('#kanji_s_reading').get(0).value = query;
	            $('#kanji_form').submit();
	            break;
	        case 'sentences':
	            $('#sentences_s_ja').get(0).value = query;
    	        $('#sentences_form').submit();
	            break;
	    }
	    
	    return false;
	};
	
	pub.clearFormForPage = function(page) {
	    switch ( page ) {
            case 'words':
                $('#words_s_en').get(0).value = '';
    	        $('#words_s_ja').get(0).value = '';
    	        $('#words_s_common').get(0).checked = false;
    	        $('#words_s_dict').get(0).value = 'edict';
    	        break;
    	    case 'kanji':
    	        $('#kanji_s_meaning').get(0).value = '';
    	        $('#kanji_s_reading').get(0).value = '';
    	        $('#kanji_s_jy').get(0).checked = false;
    	        break;
    	    case 'sentences':
    	        $('#sentences_s_en').get(0).value = '';
    	        $('#sentences_s_ja').get(0).value = '';
    	        break;
	        case 'radicals':
    	        Radicals.reset();
    	        break;
        }
	};
	
	pub.activatePage = function(page) {
        $('#menu_' + pub.currentPage).removeClass('selected');
        $('#menu_' + page).addClass('selected');
        
        $('#' + pub.currentPage).hide();
    	$('#' + page).show();

    	pub.currentPage = page;
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
		$('#radicals_result_ul').empty();
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
			var new_id = "rand_" + pub.rand(100) + "_" + radical.id;

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
		
		$('#radicals .status').text('Searching ...');
		
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
				
				if ( data.count == 0 ) {
				    $('#radicals_result_ul').hide();
				}
				else {
				    $('#radicals .result').show();
				    $('#radicals_result_ul').show();
			    }
				result_ul = $('#radicals_result_ul').get(0);
				
				// Header
				$('#radicals .status').html("Found "+ data.count +" kanji <small>"+ data.notice +"</small>");
				
				// Insert kanjis
				kanjis = '' // Do all computations first, then insert
				current_strokes = 0;
				$.each(data.kanji, function(i, kanji){
					if ( current_strokes < kanji.strokes ) {
						kanjis = kanjis + '<span>'+ kanji.strokes +'</span>';
						current_strokes = kanji.strokes;
					}
					
					kanjis = kanjis + '<a href="#kanji" onClick="iPhone.doRelatedSearch(\'kanji\',\'&#' + kanji.ord + ';\');" class="' + kanji.grade + '">&#' + kanji.ord + ';</a>';
				});
				
				$(result_ul).empty().html('<li>' + kanjis + '</li>');
				
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
	
	pub.rand = function(n) {
	  return ( Math.floor ( Math.random ( ) * n + 1 ) );
	};
	
	return pub;
}();

// ==============================
// = Handler for the menu links =
// ==============================
$('#menu li a').click(function (event){
    newPage = this.href.substr(this.href.indexOf('#')+1);
    
    if ( newPage == iPhone.currentPage ) {
        // Clear the current page's form
        iPhone.clearFormForPage(newPage);
        $('#' + newPage + ' .result').hide();
    }
    else {
        // Activate requested page
        iPhone.activatePage(newPage);        
    }
});


// ===============
// = Word search =
// ===============
$('#words_form').submit(function() {
    $('#words .result').show();
    $('#words .status').text('Searching ...');
    $('#words .result ul').hide();
    
    iPhone.doWordSearchForPage(1);
    
    return false;
});


// ================
// = Kanji search =
// ================
$('#kanji_form').submit(function() {
    $('#kanji .result').show();
    $('#kanji .status').text('Searching ...');
    $('#kanji .result ul').hide();
    
    iPhone.doKanjiSearchForPage(1);
    
    return false;
});


// ===================
// = Sentence search =
// ===================
$('#sentences_form').submit(function() {
    $('#sentences .result').show();
    $('#sentences .status').text('Searching ...');
    $('#sentences .result ul').hide();
    
    iPhone.doSentenceSearchForPage(1);
    
    return false;
});


// =======================
// = Initialize the page =
// =======================
$(document).ready(function() {
	//setTimeout(iPhone.hideSafariChrome, 100);
	
	// Check if we're reloading a specific page
    re = /#(words|kanji|radicals|sentences)/i;
    matches = document.URL.match(re);
    
    if ( matches ) {
        page = matches[1];
    }
    else {
     // Show word search as default
        page = 'words';
    }
    
    Radicals.activate();
	
	iPhone.activatePage(page);
});
