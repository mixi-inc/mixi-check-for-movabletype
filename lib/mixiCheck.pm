package mixiCheck;

use strict;
use warnings;
use Encode;
use MT::Util qw ( encode_html );
use base qw( MT::App );

my $plugin = MT->component('MixiCheck');

sub cfg_mixi_check {
    my $app  = shift;
    my $tmpl = $plugin->load_tmpl('mixi_check_settings.tmpl');

    my $mixi_check_key = $plugin->get_config_value('mixi_check_key', 'website') || '';
    my $is_adult       = $plugin->get_config_value('is_adult', 'website') || '0';
    my $robots         = $plugin->get_config_value('robots', 'website') || '';
    my $button_type    = $plugin->get_config_value('button_type', 'website') || 'button-1';

    my %param;
    $param{page_title}      = $plugin->translate('mixi Check Settings');
    $param{mixi_check_key}  = encode_html($mixi_check_key);
    $param{is_adult}        = $is_adult;
    for (split ",", $robots) {
        $param{"robots_$_"} = 1;
    }
    $param{$button_type}    = 1;

    return $app->build_page($tmpl, \%param);
}

sub save_settings {
    my $app  = shift;
    my $q    = $app->{query};

    my $mixi_check_key = $q->param('mixi_check_key') || '';
    my $is_adult       = $q->param('is_adult') || '';
    my @robots         = $q->param('robots') || ();
    my $robots         = join ",", @robots;
    my $button_type    = $q->param('button_type') || '';

    $plugin->set_config_value('mixi_check_key', $mixi_check_key, 'website');
    $plugin->set_config_value('is_adult', $is_adult, 'website');
    $plugin->set_config_value('robots', $robots, 'website');
    $plugin->set_config_value('button_type', $button_type, 'website');

    cfg_mixi_check($app);
}

sub _hdlr_mixi_check_header {
    my ($ctx, $args) = @_;
    my $blog = $ctx->stash('blog')
        or return $ctx->_no_blog_error($ctx->stash('tag'));
    my $site_name = encode_html($blog->name);
    my $entry = $ctx->stash('entry');
    my ($title, $description);
    if ($entry) {
        $title = $site_name . " - " . encode_html($entry->title);
        $description = encode_html($entry->get_excerpt) || '';
    } else {
        $title = $site_name;
        $description = encode_html($blog->description) || '';
    }
    my $is_adult = $plugin->get_config_value('is_adult', 'website');
    my $rating   = $is_adult eq 'on' ? 1 : 0;
    my $robots   = encode_html($plugin->get_config_value('robots', 'website'));

    return qq(
<meta property="og:site_name" content="$site_name" />
<meta property="og:title" content="$title" />
<meta property="og:description" content="$description" />
<meta property="mixi:content-rating" content="$rating" />
<meta name="mixi-check-robots" content="$robots" />
);
}

sub _hdlr_mixi_check_button {
    my ($ctx, $args) = @_;

    my $entry = $ctx->stash('entry')
	or return $ctx->_no_entry_error($ctx->stash('tag'));
    my $url            = encode_html($entry->permalink);
    my $mixi_check_key = encode_html($plugin->get_config_value('mixi_check_key', 'website'));
    my $button_type    = encode_html($plugin->get_config_value('button_type', 'website'));

    return qq(
<a href="http://mixi.jp/share.pl" class="mixi-check-button" data-key="$mixi_check_key" data-url="$url" data-button="$button_type">Check</a>
<script type="text/javascript" src="http://static.mixi.jp/js/share.js"></script>
);
}

sub _hdlr_mixi_check_button_mb {
    my ($ctx, $args) = @_;

    my $blog = $ctx->stash('blog')
        or return $ctx->_no_blog_error($ctx->stash('tag'));
    my $site_name = encode_html($blog->name);
    my $entry = $ctx->stash('entry')
	or return $ctx->_no_entry_error($ctx->stash('tag'));
    my $url            = encode_html($entry->permalink);
    my $entry_text     = $entry->text . $entry->text_more;

    my $mixi_check_key = encode_html($plugin->get_config_value('mixi_check_key', 'website'));
    my $button_type    = encode_html($plugin->get_config_value('button_type', 'website'));
    my $is_adult       = $plugin->get_config_value('is_adult', 'website');
    my $rating         = $is_adult eq 'on' ? 1 : 0;
    my $robots         = encode_html($plugin->get_config_value('robots', 'website'));

    my $title = '';
    if ($robots !~ /notitle/) {
        $title = $site_name . " - " . encode_html($entry->title);
    }
    my $description = '';
    if ($robots !~ /nodescription/) {
        $description = encode_html($entry->get_excerpt) || '';
    }
    my @images = ();
    if ($robots !~ /noimage/) {
	for ($entry_text =~ /<\s*?img(.*?)>/sgi) {
	    my $img = $_;
	    my $img_src = '';
	    if ($img =~ /src\s*?=\s*?\"(.*?)\"/i) {
		$img_src = $1;
	    }
	    push @images, $img_src;
	}
    }

    my $submit_text = 'mixiﾁｪｯｸ';
    Encode::_utf8_on($submit_text);
    
    return qq(
<form method="post" action="http://m.mixi.jp/share.pl?guid=ON">
<input type="hidden" name="check_key" value="$mixi_check_key" />
<input type="hidden" name="title" value="$title" />
<input type="hidden" name="description" value="$description" />
<input type="hidden" name="content_rating" value="$rating" />
<input type="hidden" name="image" value="$images[0]" />
<input type="hidden" name="primary_url" value="$url" />
<input type="hidden" name="mobile_url" value="$url" />
<input type="submit" value="$submit_text" />
</form>
);
}

1;
