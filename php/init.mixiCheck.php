<?php

global $mt;
$ctx = &$mt->context();

$ctx->add_tag('mixicheckheader', 'mixi_check_header');
$ctx->add_tag('mixicheckbutton', 'mixi_check_button');
$ctx->add_tag('mixicheckbuttonmb', 'mixi_check_button_mb');

function mixi_check_header($args, &$ctx) {
  $blog = $ctx->stash('blog');
  if (!$blog) {
    return $ctx->error("No blog available");
  }
  $site_name = smarty_modifier_encode_html($blog->blog_name);
  $entry = $ctx->stash('entry');
  if ($entry) {
    $title = $site_name . " - " . smarty_modifier_encode_html($entry->title);
    $description = smarty_modifier_encode_html(smarty_function_mtentryexcerpt($args, $ctx));
  } else {
    $title = $site_name;
    $description = smarty_modifier_encode_html($blog->blog_description);
  }
  $config = $ctx->mt->db()->fetch_plugin_data('mixiCheck', "configuration:website");
  $is_adult = $config['is_adult'];
  $rating   = $is_adult == 'on' ? 1 : 0;
  $robots   = smarty_modifier_encode_html($config['robots']);
  
  $content = <<<EOT
<meta property="og:site_name" content="$site_name" />
<meta property="og:title" content="$title" />
<meta property="og:description" content="$description" />
<meta property="mixi:content-rating" content="$rating" />
<meta name="mixi-check-robots" content="$robots" />
EOT;
  return $content;
}

function mixi_check_button($args, &$ctx) {
  $entry = $ctx->stash('entry');
  if (!$entry) {
    return $ctx->error("No entry available");
  }
  $url = smarty_modifier_encode_html(smarty_function_mtentrypermalink($args, $ctx));
  $config = $ctx->mt->db()->fetch_plugin_data('mixiCheck', "configuration:website");
  $mixi_check_key = smarty_modifier_encode_html($config['mixi_check_key']);
  $button_type    = smarty_modifier_encode_html($config['button_type']);
  
  $content = <<<EOT
<a href="http://mixi.jp/share.pl" class="mixi-check-button" data-key="$mixi_check_key" data-url="$url" data-button="$button_type">check!</a>
<script type="text/javascript" src="http://static.mixi.jp/js/share.js"></script>
EOT;
  return $content;
}

function mixi_check_button_mb($args, &$ctx) {
  $blog = $ctx->stash('blog');
  if (!$blog) {
    return $ctx->error("No blog available");
  }
  $entry = $ctx->stash('entry');
  if (!$entry) {
    return $ctx->error("No entry available");
  }
  $site_name = smarty_modifier_encode_html($blog->blog_name);
  $url = smarty_modifier_encode_html(smarty_function_mtentrypermalink($args, $ctx));
  $entry_text = $entry->entry_text . $entry->entry_text_more;
  
  $config = $ctx->mt->db()->fetch_plugin_data('mixiCheck', "configuration:website");
  $mixi_check_key = smarty_modifier_encode_html($config['mixi_check_key']);
  $button_type    = smarty_modifier_encode_html($config['button_type']);
  $is_adult       = $config['is_adult'];
  $rating         = $is_adult == 'on' ? 1 : 0;
  $robots         = smarty_modifier_encode_html($config['robots']);

  if (!preg_match("/notitle/", $robots)) {
    $title = $site_name . " - " . smarty_modifier_encode_html($entry->title);
  }
  if (!preg_match("/nodescription/", $robots)) {
    $description = smarty_modifier_encode_html(smarty_function_mtentryexcerpt($args, $ctx));
  }
  if (!preg_match("/noimage/", $robots)) {
    preg_match_all("/<\s*?img.*?src\s*?=\s*?\"(.*?)\"/si", $entry_text, $images, PREG_SET_ORDER);
    $image = $images[0][1];
  }

  $content = <<<EOT
<form method="post" action="http://m.mixi.jp/share.pl?guid=ON">
<input type="hidden" name="check_key" value="$mixi_check_key" />
<input type="hidden" name="title" value="$title" />
<input type="hidden" name="description" value="$description" />
<input type="hidden" name="content_rating" value="$rating" />
<input type="hidden" name="image" value="$image" />
<input type="hidden" name="primary_url" value="$url" />
<input type="hidden" name="mobile_url" value="$url" />
<input type="submit" value="mixiﾁｪｯｸ" />
</form>
EOT;
  return $content;
}