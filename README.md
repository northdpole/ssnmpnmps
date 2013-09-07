ssnmpnmps
=========

Simple snmp Network Management System

Για την αναπτυξη του συστήματος χρησιμοποιήθηκαν οι γλώσσες perl και php.
Η κύρια λειτουργικότητα του συστήματος έχει γραφτεί σε perl με χρήση των 
παρακάτω modules:
GD
Net
DBI/DBD
ενώ η οπτική αναπαράσταση των στοιχείων γίνετaι
και μέσω browser χρησιμοποιώντας php
και την php βιβλιοθήκη jpgraph.

Επιλέχθηκε η perl γιατί είναι μια πολύ διάσημη γλώσσα μεταξύ των
διαχειριστών δικτύων και έχει πολύ καλή διασύνδεση με τη γραμμή εντολών,
άρα διευκολύνεται η ενσωμάτοση του συστήματος σε άλλα scripts.
Επίσης η perl είναι μια γλώσσα που μπορεί να τρέξει σε όλα τα σύγχρονα
λειτουργικά συστήματα πράγμα που επιτρέπει την εγκατάσταση του συστήματος 
οπουδήποτε.

Αποφασίσαμε να υλοποιήσουμε οπτική αναπαράσταση και μέσω php για να
διευκολύνουμε την οπτικοποίηση των στοιχείων και την πρόσβαση στην πληροφορία
απο οποιοδήποτε υπολογιστή ακόμα κι αν δεν τρέχει την εφαρμογή.

Θεωρούμε ότι οι hosts έχουν ήδη εγκατεστημένα και configured snmp daemons
Η παρακολούθηση και η προσθήκη των hosts/services είναι ανεξάρτητη
και γίνεται δυναμικά, δηλαδή οι hosts μπορούν να προσθαφαιρεθούν απο τη
βάση χωρίς να χρειαστεί επανεκκίνηση της εφαρμογής.

Οι εναλλακτικές που απορίψαμε ήταν:

Δημιουργία πλήρως web interface <- απορίφθηκε λόγο περιορισμένου χρόνου
επίσης θεωρήθηκε ποιο admin-friendly η συλλογή απο scripts

Συγγραφή του προγράμματος σε java <- Δεδομένου ότι πρόκειται
για μικρή εφαρμογή θεωρήθηκε πιο γρήγορο να γραφτεί σε scripting γλώσσες.
Επίσης η perl είναι πολύ πιο ευέλικτη απο τη java άρα δίνει
και περισσότερη ελευθερία στον administrator για να ενσωματώσει το σύστημα
στα δικά του monitoring scripts.

Αν είχαμε θεωρητικά άπειρο χρόνο θα υλοποιούσαμε περισσότερα features ώστε να γίνει ολοκληρωμένο project
επίσης θα υλοποιούσαμε security checks και snmp v3 feature support όπως certificates, usernames και passwords.

Παραδείγματα των features που θα μπορούσαν να υλοποιηθούν είναι:
Υποστήριξη αρχείων που θα δίνονταν στα scripts ώστε να γίνουν monitor
συγκεκριμένες ip που ίσως να μην ανήκουν στο ίδιο subnet.
Αντίστοιχα για κάποιο υποσύνολο των services σε ένα host.

Θα μπορούσε να υλοποιηθεί ένα feature που θα μετέφραζε
τα oids σε human readable form.

Θα μπορούσε να υλοποιηθεί network discovery/crawling ώστε νέα hosts
να προστίθενται δυναμικά στο σύστημα και αντίστοιχα 
snmwalk ώστε να προστίθενται και νέα oids.

Ορισμός traps,actions και alerts ώστε
ανάλογα με το πιο trap ενεργοποιήθηκε να μπορεί να γίνει το αντίστοιχο action
(π.χ. αποστολή email στον admin ή αποστολή κάποιας εντολής στον host).



Η λειτουργικότητα του project αναλύεται παρακάτω μαζί με οδηγίες χρήσης

Το σύστημα αποτελείται απο μια βάση και μια συλλογή απο scripts.
Η βάση χρησιμοποιείται για την αποθήκευση πληροφοριών όπως:
	- Hosts
	- Oids
	- Results
	- Users
Ο χρήστης εισάγει κόμβους στο σύστημα
είτε κατευθείαν στη βάση με κάποιο mysql insert query
ή χρησιμοποιώντας το script add_host.pl με τον ακόλουθο τρόπο

" 
	perl add_host.pl $hostip $host_identifier $community
Για παράδειγμα:	
	perl add_host.pl 192.168.1.23 the_thing public
	μπορεί επίσησ να χρησιμοποιηθεί σε ολόκληρο υποδίκτυο ως εξής
	perl add_host.pl 192.168.1.23/23  the_thing public
"

Εισάγει services που μπορούν να γίνουν monitor για τον host επίσης 
είτε με κάποιο mysql insert query ή χρησιμοποιώντας το script add_service.pl
ως εξής

"
	perl add_service.pl $hostip ($community $OID) <-- προεραιτικά
Για παράδειγμα
	perl add_service.pl 192.168.1.23  public 1.3.6.1.2.1.2.1.0 or
	perl add_service.pl 192.168.1.23  public
μπορεί επίσης να χρησιμοποιηθεί για υποδίκτυο ως εξής
	perl add_service.pl 192.168.1.23/23  public 1.3.6.1.2.1.2.1.0
	
αν δεν δοθεί κάποιο community id θ αποθηκευτεί αυτό που έχει οριστεί στο conf.pl
αν δεν δοθεί κάποιο oid θ αποθηεκυτεί η λίστα με τα defaults η οποία είναι η εξής:
						 '.1.3.6.1.4.1.2021.10.1.3.1',	
						 '.1.3.6.1.4.1.2021.10.1.3.2',
						 '.1.3.6.1.4.1.2021.10.1.3.3',
						 '.1.3.6.1.4.1.2021.11.9.0',
						 '.1.3.6.1.4.1.2021.11.50.0',
						 '.1.3.6.1.4.1.2021.11.10.0',
						 '.1.3.6.1.4.1.2021.11.52.0',
						 '.1.3.6.1.4.1.2021.11.11.0',
						 '.1.3.6.1.4.1.2021.11.53.0',
						 '.1.3.6.1.4.1.2021.11.51.0',
						 '.1.3.6.1.4.1.2021.4.3.0',
						 '.1.3.6.1.4.1.2021.4.4.0',
						 '.1.3.6.1.4.1.2021.4.5.0',
						 '.1.3.6.1.4.1.2021.4.6.0',
						 '.1.3.6.1.4.1.2021.4.11.0',
						 '.1.3.6.1.4.1.2021.4.13.0',
						 '.1.3.6.1.4.1.2021.4.14.0',
						 '.1.3.6.1.4.1.2021.4.15.0',
						 '.1.3.6.1.4.1.2021.9.1.2.1',
						 '.1.3.6.1.4.1.2021.9.1.3.1',
						 '.1.3.6.1.4.1.2021.9.1.6.1',
						 '.1.3.6.1.4.1.2021.9.1.7.1',
						 '.1.3.6.1.4.1.2021.9.1.8.1',
						 '.1.3.6.1.4.1.2021.9.1.9.1',
						 '.1.3.6.1.4.1.2021.9.1.10.1',
						 '.1.3.6.1.2.1.1.3.0'
"
Μπορεί ν αποθηκεύσει στη βάση τ' αποτελέσματα για κάποιο
συγκεκριμένο host για όλα τα oids του host
καλώντας το script get_remote_info.pl ως εξής

perl get_remote_info.pl [$hostip] [-v]

Με την επιλογή -v εκτυπώνεται στην κονσόλα το ποιος host ρωτήθηκε για ποιο oid.

Το script daemon.pl χρησιμοποιείται ως εξής

	perl daemon.pl probing_frequency(in seconds) [$ip (with or without net mask)] [-v or -vv](for message output to stdout)
οι επιλογές -v -vv ρυθμίζουν το ποσό των εκτυπώσιμων μυνημάτων.

Το αρχείο conf.pl περιέχει πληροφορίες απαραίτητες για τη ρύθμιση
του συστήματος όπως τους κωδικούς και τον host της βάσης,
το default community_string για το snmp κ.α. που περιγράφονται στο αρχείο

Το αρχείο database.pl περιέχει τις εντολές για το στήσιμο του mysql database.
Το report_data.pl καλείται για οπτικοποίηση των δεδομένων
που έχει μαζέψει μέχρι στιγμής ο daemon
Τα γραφήματα που παράγει το report_data.pl αποθηκεύονται στο φάκελο graphs

Το σύστημα περιλαμβάνει επίσης μια συλλογή απο php scripts τα οποία
αναλαμβάνουν την οπτικοποίηση των δεδομένων με γραφικό τρόπο μέσω browser.
Για την πρόσβαση στο γραφικό web περιβάλλον το όνομα χρήστη
και ο κωδικός ορίζονται στο database.pl ως admin admin


Παράδειγμα εγκατάστασης και χρήσης του συστήματος:

cd στον φάκελο που είναι το project
emacs conf.pl
εισαγωγή των απαραίτητων ρυθμίσεων
perl database.pl
perl add_host.pl $ip_του_host_που_θέλουμε_με_ή_χωρίς_το_subnet
perl add_service.pl $ip_του_host_που_θέλουμε_με_ή_χωρίς_το_subnet και προεραιτικά κάποιο oid και κάποιο community string
perl daemon.pl κάθε_πόσα_δευτερόλεπτα_θα_ζητούνται_πληροφορίες_για_όλους_τους_hosts ή για την ip ή το υποδίκτυο που θα δοθεί
