# Example usage:
# let
#  kubeconfig = (import (pkgs.fetchFromGitHub {
#    owner = "szamuboy";
#    repo = "kubeconfig-nix";
#    rev = "c286b7b86ad3a78583a63ab58049b281d2a7ff70";
#    sha256 = "sha256-aczuBQuPJCmXH8m+UBKZcIgdbswPjT8FH6D2eMjCGAI=";
#  }) { inherit pkgs; });
# in pkgs.mkShell {
#  KUBECONFIG = toString (kubeconfig.kubeconfig [{
#    name = "whatever-context-name";
#    server = "https://kubernetes.endpoint.cloud:6443";
#    namespace = "project"; # default value is "default"
#    token = "blahblahsecrettoken";
#  }]);
# }
{ pkgs, ... }:
let
  content = contexts:
    assert builtins.typeOf contexts == "list";
    assert builtins.length contexts > 0; {
      apiVersion = "v1";
      kind = "Config";
      clusters = builtins.map ({ name, server, ... }: {
        inherit name;
        cluster = { inherit server; };
      }) contexts;
      users = builtins.map ({ name, token, ... }: {
        inherit name;
        user = { inherit token; };
      }) contexts;
      contexts = builtins.map ({ name, namespace ? "default", ... }: {
        inherit name;
        context = {
          inherit namespace;
          cluster = name;
          user = name;
        };
      }) contexts;
      current-context = (builtins.elemAt contexts 0).name;
    };
in {
  kubeconfig = contexts:
    (pkgs.writeTextFile {
      name = "kubeconfig";
      text = builtins.toJSON (content contexts);
    });
}
