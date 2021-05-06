unit class Mint;

use UUID;
use Red:api<2>;

has $.termination-points = set 'system', 'transfer', 'reward', 'penalty';

model Account { ... }
model Transaction { ... }

model Account is table<mint_accounts> is rw is export {
    has Str $.account is id;
    has @.transactions is relationship( *.account, :model(Transaction) );
    has Int $.overdraft is column = 0;
    has Bool $.is-frozen is column = False;
    has DateTime $.registration-date is column{ :type<timestamptz> } = DateTime.now;

    method new(Str $account) {
        self.^create(account => $account);
        say "✓ new account created for $account";
    }

    method mint(Str :$account, Int :$value) {
        my $termination-point = 'system';
        Transaction.new(:$account, :$value, :$termination-point);
    }

    method rename(Str :$account-name, Str :$new-account-name) { 
        my $a = self.^load($account-name);
        $a.account = $new-account-name;
        self.^save;
    }

    method balance() { ... }

    method set-overdraft(Str :$account, Int :$overdraft) { ... }

    method freeze(Str :$account) { ... }

    method defrost(Str :$account) { ... }
}

model Transaction is table<mint_transactions> is nullable is rw {
    has UUID $.batch is id;
    has Str $.account is id;
    has Int $.value is column;
    has Str $.from-account is referencing( *.account, :model(Account) );
    has Account $.sender is relationship(*.from-account);
    has Str $.to-account is referencing( *.account, :model(Account) );
    has Account $.recipient is relationship(*.to-account);
    has Str $.termination-point is column;
    has Bool $.is-void is column = False;
    has DateTime $.datetime is column{ :type<timestamptz> } = DateTime.now;

    method new(Str :$account, Int :$value, Str :$from-account?, Str :$to-account?, Str :$termination-point) {
        self.^create(batch => ~UUID.new, account => $account, value => $value, termination-point => $termination-point);
    }

    method void() { ... }
}

submethod TWEAK() {
    red-defaults "Pg",
            host => "localhost",
            database => "mint",
            user => "mint",
            password => "password",
            :default;

    schema(Account, Transaction).create;
}

method register-termination-points(Set $new-termination-points) {
    $.termination-points = $.termination-points (|) $new-termination-points;
    return $.termination-points;
}
