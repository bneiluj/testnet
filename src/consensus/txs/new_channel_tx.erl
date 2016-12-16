-module(new_channel_tx).
-export([doit/4, make/8]).
-record(nc, {acc1 = 0, acc2 = 0, fee = 0, nonce = 0, bal1 = 0, bal2 = 0, rent = 0, id = -1}).

make(ID,Accounts,Acc1,Acc2,Inc1,Inc2,Rent,Fee) ->
    {_, A, Proof} = account:get(Acc1, Accounts),
    Nonce = account:nonce(A),
    {_, _, Proof2} = account:get(Acc2, Accounts),
    Tx = #nc{id = ID, acc1 = Acc1, acc2 = Acc2, 
	     fee = Fee, nonce = Nonce+1, bal1 = Inc1,
	     bal2 = Inc2, rent = Rent},
    {Tx, [Proof, Proof2]}.
				 
doit(Tx, Channels, Accounts, NewHeight) ->
    ID = Tx#nc.id,
    {_, empty, _} = channel:get(ID, Channels),
    Aid1 = Tx#nc.acc1,
    Aid2 = Tx#nc.acc2,
    false = Aid1 == Aid2,
    Bal1 = Tx#nc.bal1,
    true = Bal1 >= 0,
    Bal2 = Tx#nc.bal2,
    true = Bal2 >= 0,
    Rent = Tx#nc.rent,
    NewChannel = channel:new(ID, Aid1, Aid2, Bal1, Bal2, NewHeight, Rent),
    NewChannels = channel:write(NewChannel, Channels),
    CCFee = constants:create_channel_fee(),
    Acc1 = account:update(Aid1, Accounts, -Bal1-CCFee, Tx#nc.nonce, NewHeight),
    Acc2 = account:update(Aid2, Accounts, -Bal2-CCFee, none, NewHeight),
    Accounts2 = account:write(Accounts, Acc1),
    NewAccounts = account:write(Accounts2, Acc2),
    {NewChannels, NewAccounts}.