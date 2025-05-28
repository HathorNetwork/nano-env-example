# Copyright 2023 Hathor Labs
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from hathor.nanocontracts.blueprint import Blueprint
from hathor.nanocontracts.context import Context
from hathor.nanocontracts.exception import NCFail
from hathor.nanocontracts.types import (
    Address,
    NCAction,
    NCDepositAction,
    NCWithdrawalAction,
    TokenUid,
    is_action_type,
    public,
    view,
)


class InsufficientBalance(NCFail):
    pass


class InvalidAmount(NCFail):
    pass


class TooManyActions(NCFail):
    pass


class TokenManagerBlueprint(Blueprint):
    # Token balances per address
    balances: dict[Address, int]

    # Total supply of the managed token
    total_supply: int

    # Token configuration
    token_uid: TokenUid
    owner: Address

    def _get_action(self, ctx: Context) -> NCAction:
        """Return the only action available; fails otherwise."""
        if len(ctx.actions) != 1:
            raise TooManyActions('only one action supported')
        return list(ctx.actions.values())[0][0]

    @public(allow_deposit=True)
    def initialize(self, ctx: Context, token_uid: TokenUid) -> None:
        """Initialize the token manager with a specific token."""
        action = self._get_action(ctx)
        assert is_action_type(action, NCDepositAction)

        self.token_uid = token_uid
        self.owner = Address(ctx.address)
        self.total_supply = 0

    @public(allow_deposit=True)
    def deposit(self, ctx: Context) -> None:
        """Deposit tokens to the contract."""
        action = self._get_action(ctx)
        assert is_action_type(action, NCDepositAction)

        if action.token_uid != self.token_uid:
            raise NCFail('invalid token')

        address = Address(ctx.address)
        amount = action.amount

        if address not in self.balances:
            self.balances[address] = 0

        self.balances[address] += amount
        self.total_supply += amount

    @public(allow_withdrawal=True)
    def withdraw(self, ctx: Context, amount: int) -> None:
        """Withdraw tokens from the contract."""
        if amount <= 0:
            raise InvalidAmount('amount must be positive')

        action = self._get_action(ctx)
        assert is_action_type(action, NCWithdrawalAction)

        if action.token_uid != self.token_uid:
            raise NCFail('invalid token')

        address = Address(ctx.address)

        if address not in self.balances or self.balances[address] < amount:
            raise InsufficientBalance('insufficient balance')

        if action.amount != amount:
            raise NCFail('withdrawal amount mismatch')

        self.balances[address] -= amount
        self.total_supply -= amount

    @public
    def transfer(self, ctx: Context, to_address: Address, amount: int) -> None:
        """Transfer tokens between addresses within the contract."""
        if amount <= 0:
            raise InvalidAmount('amount must be positive')

        from_address = Address(ctx.address)

        if from_address not in self.balances or self.balances[from_address] < amount:
            raise InsufficientBalance('insufficient balance')

        if to_address not in self.balances:
            self.balances[to_address] = 0

        self.balances[from_address] -= amount
        self.balances[to_address] += amount

    @view
    def get_balance(self, address: Address) -> int:
        """Get the balance of a specific address."""
        return self.balances.get(address, 0)

    @view
    def get_total_supply(self) -> int:
        """Get the total supply of tokens in the contract."""
        return self.total_supply

    @view
    def get_token_uid(self) -> TokenUid:
        """Get the managed token UID."""
        return self.token_uid

    @view
    def get_owner(self) -> Address:
        """Get the contract owner address."""
        return self.owner


__blueprint__ = TokenManagerBlueprint
