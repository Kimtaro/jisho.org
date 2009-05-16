use strict;
use warnings;
use DateTime;


# =========
# = Setup =
# =========
my $today		= DateTime->now();
my $yesterday	= DateTime->now();
my $log			= '';
my $email		= 'kim.ahlstrom@gmail.com';
my $interactive	= 1;

$today		= $today->dmy();
$yesterday->subtract( days => 1 );
$yesterday	= $yesterday->dmy();


# ========================
# = Get the latest edict =
# ========================
log_this('Fetching latest examples.utf.gz');
log_this(`curl -s -O http://www.csse.monash.edu.au/~jwb/examples.utf.gz`);

log_this('Uncompressing examples.gz');
log_this(`gunzip examples.utf.gz`);

log_this("Renaming examples.utf to examples_$today");
log_this(`mv examples.utf examples_$today`);

log_this("Creating diff with last week's file, examples_$yesterday");
my $diff = `diff examples_$yesterday examples_$today`;
log_this($diff);

log_this('Running the import script');
log_this(`perl ../importers/tanaka.pl examples_$today examples -log`);

log_this("Removing yesterday's file and the euc version of today's");
log_this(`rm examples_$yesterday examples`);

email();


# ==========================
# = Log convenience method =
# ==========================
sub log_this {
	my $message = shift || 'Command was successfull';
	my $line = DateTime->now() . " - $message\n";
	
	$log .= $line;
	
	if ($interactive) {
		print $line;
	}
}


# ==============
# = E-mail log =
# ==============
sub email {
	my $address = $email;
	my $subject = "[Jisho.org] Weekly tanaka update $today";
	my $body	= $log;
	
	open(MAIL, "| sendmail -i $address");

	print MAIL "From: Jisho.org <kim.ahlstrom\@gmail.com>\n";
	print MAIL "To: $address\n";
	print MAIL "Content-Type: text/plain; charset=UTF-8; format=flowed\n";
	print MAIL "X-DJ-Process: $$\n";
	print MAIL "Subject: $subject\n\n";
	print MAIL $body;
	close(MAIL);
}