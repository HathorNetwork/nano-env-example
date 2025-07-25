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
    NCAction,
    NCDepositAction,
    NCGrantAuthorityAction,
    NCInvokeAuthorityAction,
    NCWithdrawalAction,
    TokenUid,
    is_action_type,
    public,
)


class TooManyActions(NCFail):
    pass


class AuthorityBlueprint(Blueprint):
    def _get_action(self, ctx: Context) -> NCAction:
        """Return the only action available; fails otherwise."""
        if len(ctx.actions) != 1:
            raise TooManyActions('only one token supported')
        return list(ctx.actions.values())[0][0]

    @public(allow_deposit=True)
    def initialize(self, ctx: Context) -> None:
        # Deposit so it can have funds to pay token deposit fee
        # for create token method
        action = self._get_action(ctx)
        assert is_action_type(action, NCDepositAction)

    @public(allow_withdrawal=True)
    def create_token(self, ctx: Context) -> None:
        # Withdrawal to pay for token creation
        action = self._get_action(ctx)
        assert is_action_type(action, NCWithdrawalAction)

    @public(allow_grant_authority=True)
    def grant_authority(self, ctx: Context) -> None:
        action = self._get_action(ctx)
        assert is_action_type(action, NCGrantAuthorityAction)

    @public(allow_invoke_authority=True)
    def invoke_authority(self, ctx: Context) -> None:
        action = self._get_action(ctx)
        assert is_action_type(action, NCInvokeAuthorityAction)

    @public
    def mint(self, ctx: Context, token_uid: TokenUid, amount: int) -> None:
        self.syscall.mint_tokens(token_uid, amount)

    @public
    def melt(self, ctx: Context, token_uid: TokenUid, amount: int) -> None:
        self.syscall.melt_tokens(token_uid, amount)

    @public
    def revoke(self, ctx: Context, token_uid: TokenUid, revoke_mint: bool, revoke_melt: bool) -> None:
        self.syscall.revoke_authorities(
            token_uid=token_uid, revoke_mint=revoke_mint, revoke_melt=revoke_melt)


__blueprint__ = AuthorityBlueprint
