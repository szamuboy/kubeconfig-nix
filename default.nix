# Example usage:
# let
# kubeconfig = (import ./kubeconfig.nix { inherit pkgs; });
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
