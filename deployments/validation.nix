# Strict Nix validation between stack contracts (`stacks/<name>/stack.nix`),
# the declared topology (`./topology.nix`) and the placement inventory
# (`./inventory.nix`).
#
# Vendored from the previous `homelab` repo. The logic is generic and depends
# only on local files in this repo — no external flake input is required.
let
  topology = import ./topology.nix;
  inventory = import ./inventory.nix;

  stackRoot = ../stacks;
  stackDirEntries = builtins.readDir stackRoot;
  stackNames = builtins.filter (name:
    stackDirEntries.${name} == "directory"
    && builtins.pathExists (stackRoot + "/${name}/stack.nix")
  ) (builtins.attrNames stackDirEntries);

  stacks = builtins.listToAttrs (map (name: {
    inherit name;
    value = import (stackRoot + "/${name}/stack.nix");
  }) stackNames);

  unique = list:
    builtins.foldl' (acc: item:
      if builtins.elem item acc then acc else acc ++ [ item ]
    ) [ ] list;

  optionals = condition: items: if condition then items else [ ];
  isNonEmptyString = value: builtins.isString value && value != "";
  isListOfStrings = value: builtins.isList value && builtins.all builtins.isString value;

  requiredStackFields = [
    "name"
    "deploymentMode"
    "supportedTargets"
    "roles"
    "secrets"
    "needs"
    "volumes"
  ];

  allowedDeploymentModes = [ "singleton" "perTarget" "distributed" ];
  assignmentFields = [ "stack" "instance" "role" ];

  stackContractErrors = builtins.concatLists (map (stackName:
    let
      stack = stacks.${stackName};
      missingFields = builtins.filter (field: !(builtins.hasAttr field stack)) requiredStackFields;
    in
      (map (field: "stack '${stackName}' is missing required field '${field}'") missingFields)
      ++ optionals (builtins.hasAttr "name" stack && stack.name != stackName) [
        "stack '${stackName}' declares name '${stack.name}' instead of '${stackName}'"
      ]
      ++ optionals (!(builtins.hasAttr "deploymentMode" stack) || !(builtins.elem stack.deploymentMode allowedDeploymentModes)) [
        "stack '${stackName}' must declare deploymentMode as one of ${builtins.concatStringsSep ", " allowedDeploymentModes}"
      ]
      ++ optionals (!(builtins.hasAttr "supportedTargets" stack) || !(isListOfStrings stack.supportedTargets) || stack.supportedTargets == [ ]) [
        "stack '${stackName}' must declare a non-empty supportedTargets list"
      ]
      ++ optionals (!(builtins.hasAttr "roles" stack) || !(isListOfStrings stack.roles)) [
        "stack '${stackName}' must declare roles as a list of strings"
      ]
      ++ optionals (!(builtins.hasAttr "secrets" stack) || !(isListOfStrings stack.secrets)) [
        "stack '${stackName}' must declare secrets as a list of strings"
      ]
      ++ optionals (!(builtins.hasAttr "needs" stack) || !(isListOfStrings stack.needs)) [
        "stack '${stackName}' must declare needs as a list of strings"
      ]
      ++ optionals (!(builtins.hasAttr "volumes" stack) || !(isListOfStrings stack.volumes)) [
        "stack '${stackName}' must declare volumes as a list of strings"
      ]
    ) stackNames);

  targetNames = builtins.attrNames topology.targets;
  assignmentTargetNames = builtins.attrNames inventory.assignments;

  assignmentErrors = builtins.concatLists (map (targetName:
    if !(builtins.hasAttr targetName topology.targets) then
      [ "inventory defines assignments for unknown target '${targetName}'" ]
    else
      let
        target = topology.targets.${targetName};
        assignments = inventory.assignments.${targetName};
        safeAssignments = if builtins.isList assignments then assignments else [ ];
        indexedAssignments = builtins.genList (index: {
          inherit index;
          value = builtins.elemAt safeAssignments index;
        }) (builtins.length safeAssignments);

        perAssignmentErrors =
          optionals (!builtins.isList assignments) [
            "assignments for target '${targetName}' must be a list"
          ]
          ++ builtins.concatLists (map ({ index, value }:
            let
              label = "assignment ${toString (index + 1)} on target '${targetName}'";
              extraFields = if builtins.isAttrs value then builtins.filter (field: !(builtins.elem field assignmentFields)) (builtins.attrNames value) else [ ];
              stackName = if builtins.isAttrs value && builtins.hasAttr "stack" value then value.stack else null;
              stackExists = builtins.isString stackName && builtins.hasAttr stackName stacks;
              role = if builtins.isAttrs value && builtins.hasAttr "role" value then value.role else null;
            in
              optionals (!builtins.isAttrs value) [ "${label} must be an attribute set" ]
              ++ optionals (builtins.isAttrs value && !(builtins.hasAttr "stack" value)) [ "${label} is missing required field 'stack'" ]
              ++ optionals (builtins.isAttrs value && !(builtins.hasAttr "instance" value)) [ "${label} is missing required field 'instance'" ]
              ++ optionals (builtins.isAttrs value && builtins.hasAttr "stack" value && !isNonEmptyString value.stack) [ "${label} must declare a non-empty stack name" ]
              ++ optionals (builtins.isAttrs value && builtins.hasAttr "instance" value && !isNonEmptyString value.instance) [ "${label} must declare a non-empty instance name" ]
              ++ optionals (builtins.isAttrs value && builtins.hasAttr "role" value && !isNonEmptyString value.role) [ "${label} role must be a non-empty string when present" ]
              ++ map (field: "${label} uses unsupported field '${field}'") extraFields
              ++ optionals (builtins.isAttrs value && builtins.hasAttr "stack" value && builtins.isString value.stack && !stackExists) [ "${label} references unknown stack '${value.stack}'" ]
              ++ optionals (stackExists && role != null && !(builtins.elem role stacks.${stackName}.roles)) [ "${label} references role '${role}' which is not declared by stack '${stackName}'" ]
              ++ optionals (stackExists && !(builtins.elem target.kind stacks.${stackName}.supportedTargets)) [ "${label} assigns stack '${stackName}' to target kind '${target.kind}' which is not supported" ]
          ) indexedAssignments);

        instanceNames = map (assignment: assignment.instance) (builtins.filter (assignment: builtins.isAttrs assignment && builtins.hasAttr "instance" assignment && isNonEmptyString assignment.instance) safeAssignments);
        duplicateInstances = builtins.filter (name: builtins.length (builtins.filter (candidate: candidate == name) instanceNames) > 1) (unique instanceNames);
        perTargetStacks = unique (map (assignment: assignment.stack) (builtins.filter (assignment:
          builtins.isAttrs assignment
          && builtins.hasAttr "stack" assignment
          && builtins.isString assignment.stack
          && builtins.hasAttr assignment.stack stacks
          && stacks.${assignment.stack}.deploymentMode == "perTarget"
        ) safeAssignments));
        perTargetDuplicates = builtins.filter (stackName: builtins.length (builtins.filter (assignment:
          builtins.isAttrs assignment
          && builtins.hasAttr "stack" assignment
          && assignment.stack == stackName
        ) safeAssignments) > 1) perTargetStacks;
      in
        perAssignmentErrors
        ++ map (instanceName: "target '${targetName}' defines duplicate instance '${instanceName}'") duplicateInstances
        ++ map (stackName: "perTarget stack '${stackName}' is assigned multiple times on target '${targetName}'") perTargetDuplicates
  ) assignmentTargetNames);

  singletonErrors = builtins.concatLists (map (stackName:
    let
      assignments = builtins.concatLists (map (targetName:
        map (assignment: assignment // { target = targetName; })
          (builtins.filter (assignment:
            builtins.isAttrs assignment
            && builtins.hasAttr "stack" assignment
            && assignment.stack == stackName
          ) (if builtins.isList inventory.assignments.${targetName} then inventory.assignments.${targetName} else [ ]))
      ) assignmentTargetNames);
    in
      optionals (builtins.hasAttr stackName stacks && stacks.${stackName}.deploymentMode == "singleton" && builtins.length assignments > 1) [
        "singleton stack '${stackName}' is assigned ${toString (builtins.length assignments)} times"
      ]
  ) stackNames);

  summary = {
    stackCount = builtins.length stackNames;
    targetCount = builtins.length targetNames;
    assignmentCount = builtins.foldl' (count: targetName:
      count + builtins.length (if builtins.isList inventory.assignments.${targetName} then inventory.assignments.${targetName} else [ ])
    ) 0 assignmentTargetNames;
  };

  errors =
    stackContractErrors
    ++ assignmentErrors
    ++ singletonErrors;

  summaryText = builtins.concatStringsSep "\n" [
    "Inventory validation succeeded."
    "- targets: ${toString summary.targetCount}"
    "- stack contracts: ${toString summary.stackCount}"
    "- assignments: ${toString summary.assignmentCount}"
  ];

  report = {
    inherit topology inventory stacks summary errors summaryText;
    ok = errors == [ ];
  };
in
if report.ok then report else throw ''
Inventory validation failed:
- ${builtins.concatStringsSep "\n- " report.errors}
''
