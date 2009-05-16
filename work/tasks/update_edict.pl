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
my $success		= 0;

$today		= $today->dmy();
$yesterday->subtract( days => 1 );
$yesterday	= $yesterday->dmy();


# ========================
# = Get the latest edict =
# ========================
execute(	'Fetching latest edict',
			'rsync -t ftp.monash.edu.au::nihongo/edict ./');

execute(	"Renaming edict to edict_$today",
			"mv edict edict_$today");

execute(	'Running the import script',
			"perl ../importers/edict.pl edict_$today");

execute(	"Removing yesterday's file",
			"rm edict_$yesterday");

# Done
$success = 1;
email();


# ==================================
# = Execute command with a comment =
# ==================================
sub execute {
	my($message, $command) = @_;

	# Log
	my $line = DateTime->now() . " - $message\n";
	$log .= $line;
	print $line;
	

	# Check if the command is a sub or a program
	if ( ref($command) eq 'CODE' ) {
		&$command();
	}
	else {
		# diff's exit status is not 0 when it found differences, so just ignore it
		if ( system($command) != 0 && $command !~ m/^diff/ ) {
			$line = DateTime->now() . " - '$command' failed: $?\n";
			$log .= $line;
			print $line;
			email();
			exit 1;
		}
	}
}


# ==============
# = E-mail log =
# ==============
sub email {
	my $address = $email;
	my $subject;
	my $body	= $log;
	
	if ( $success ) {
		$subject = "[Jisho.org] Daily edict update $today";
	}
	else {
		$subject = "[Jisho.org] FAILED Daily edict update $today";
	}
	
	open(MAIL, "| sendmail -i $address");

	print MAIL "From: Jisho.org <kim.ahlstrom\@gmail.com>\n";
	print MAIL "To: $address\n";
	print MAIL "Content-Type: text/plain; charset=UTF-8; format=flowed\n";
	print MAIL "X-DJ-Process: $$\n";
	print MAIL "Subject: $subject\n\n";
	print MAIL $body;
	close(MAIL);
}
