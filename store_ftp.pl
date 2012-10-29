#!/usr/bin/perl
# Copy and rotate backup files on remote FTP server.
# Usage: ./store_ftp.pl /path/to/backup/file1.tgz /path/to/backup/file2.tgz ... /path/to/backup/fileN.tgz 

use Net::FTP;
use File::Basename;

#FTP settings
my $host = "hostname";
my $login = "login";
my $password = "pass";
my @remote_files;

# Rotation depth
my $n = 5;

$ftp = Net::FTP->new($host, Debug => 0) or die "Cannot connect to $host: $@";
$ftp->login($login, $password) or die "Cannot login otrs", $ftp->message;
$ftp->cwd("backup") or die "Cannot change working directory ", $ftp->message;

while ($path = shift @ARGV) {
        my $file = basename($path);
        print "---------------------------------------\n";
        print "Processing $path:\n";
        # old backup deleting
        print "Remove old backup...\n";
        @remote_files = $ftp->ls();
        foreach my $cur_file (@remote_files) {
                if ($cur_file eq $file.".".($n - 1)) {
                        print "  Delete $cur_file\n";
                        $ftp->delete($cur_file) or die "Cannot delete old backup $cur_file\n";
                }
        }
        print "Old backup removed!\n\n";

        # backup rotate
        print "Backups rotation...\n";
        for ($i = $n - 2; $i > 0; --$i) {
                $j = $i + 1;
                foreach $cur_file (@remote_files) {
                        $name = $new_name = $cur_file;
                        if ($name eq $file.".".$i) {
                                $new_name =~ s/\.$i$/\.$j/;
                                print "  $name -> $new_name\n";
                                $ftp->rename($name, $new_name) or die "Cannot rename $name to $new_name\n";
                        }
                }
        }
        print "Backups rotated!\n\n";

        # backup store
        print "Rename last backup...\n";
        foreach $cur_file (@remote_files) {
                $name = $new_name = $cur_file;
                if ($name eq $file) {
                        $new_name = $name.".1";
                        print "  $name -> $new_name\n";
                        $ftp->rename ($name, $new_name) or die "Can't rename $name\n", $ftp->message;
                }
        }
        print "Last backup renamed!\n\n";
        print "Storing new backup!\n";
        print "  Store $path...\n";
        $ftp->put("$path", "$file") or die "Can't PUT $path to remote FTP\n", $ftp->message;
        print "New backup stored!\n\n";

}

$ftp->quit;
