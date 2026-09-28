# Fix Netflix VPN failing at "Unexpected response to IF-T/TLS version
# negotiation" when the Ivanti gateway splits one message across TLS records.
#
# This is an exact backport of OpenConnect MR !651 commit 15351443, which adds
# recv_ift_full(): it reads the complete 16-byte IF-T header, validates the
# declared message length, and reads exactly the remaining bytes without
# consuming the next message. It replaces all five auth-phase single-read call
# sites. This supersedes the original local recv_ift_packet_full() workaround.
#
# Keep the v9.20 source so this overlay changes only the framing fix relative
# to the already-tested local package. MR !651's companion commit 8b33fa9
# handles a separate coalesced post-auth configuration case, but does not apply
# cleanly to v9.20; consume that through a newer upstream base or release
# rather than maintaining another local adaptation.
final: prev:
{
  openconnect = prev.openconnect.overrideAttrs (old: {
    version = "9.20";
    src = prev.fetchgit {
      url = "https://gitlab.com/openconnect/openconnect.git";
      rev = "8ae87c089bac597d9e09902bbedd03e0c45d8269";
      hash = "sha256-EgCe/Qv5Y9syhSq/uJuB8pOf5DWfrXjW3LXjg1VXB+U=";
    };
    patches = (old.patches or [ ]) ++ [ ./openconnect-ift-short-read.patch ];
  });
}
