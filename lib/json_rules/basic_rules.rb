raw_fatal_assertion jq: '.Resources|length > 0',
                    message: 'Must have at least 1 resource'


%w(
  AWS::IAM::Role
  AWS::IAM::Policy
  AWS::IAM::ManagedPolicy
  AWS::IAM::UserToGroupAddition
  AWS::EC2::SecurityGroup
  AWS::EC2::SecurityGroupIngress
  AWS::EC2::SecurityGroupEgress
).each do |resource_must_have_properties|
  fatal_violation jq: "[.Resources|with_entries(.value.LogicalResourceId = .key)[] | select(.Type == \"#{resource_must_have_properties}\" and .Properties == null)]|map(.LogicalResourceId)",
                  message: "#{resource_must_have_properties} must have Properties"
end

missing_reference_jq = <<END
  (
    (
      ([..|.Ref?]|map(select(. != null)) +  [..|."Fn::GetAtt"?[0]]|map(select(. != null)))
    )
    -
    (
      ["AWS::AccountId","AWS::StackName","AWS::Region","AWS::StackId","AWS::NoValue"] +
      ([.Resources|keys]|flatten) +
      (if .Parameters? then ([.Parameters|keys]|flatten) else [] end)
    )
  )|if length==0 then false else . end
END

raw_fatal_violation jq: missing_reference_jq,
                    message: 'All Ref and Fn::GetAtt must reference existing logical resource ids'


