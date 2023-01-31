import 'package:gql/src/ast/ast.dart';
import 'package:graphql_codegen/graphql_codegen.dart';
import 'package:graphql_codegen/src/transform/transforming_visitor.dart';

// TODO: Can clean this up with reflection or code-gen-inception
class ClientDirectivesTransformationVisitor extends RecursiveTransformingVisitor {
  final Set<String> _clientDirectives;

  ClientDirectivesTransformationVisitor({
    required GraphQLCodegenConfig config,
  }) : _clientDirectives = config.clientDirectives.toSet();

  List<DirectiveNode> _effectiveClientDirectives<N extends Node>(
    N node,
    List<DirectiveNode> Function(N) accessor,
  ) =>
      [...accessor(node)]
          .where(
            (e) => !_clientDirectives.contains(e.name.value),
          )
          .toList();

  @override
  OperationDefinitionNode visitOperationDefinitionNode(OperationDefinitionNode node) {
    return OperationDefinitionNode(
      name: visitOne(node.name),
      directives: _effectiveClientDirectives<OperationDefinitionNode>(node, (n) => n.directives),
      type: node.type,
      selectionSet: visitOne(node.selectionSet),
      variableDefinitions: visitAll(node.variableDefinitions),
    );
  }

  @override
  FieldNode visitFieldNode(FieldNode node) {
    return FieldNode(
      name: visitOne(node.name),
      directives: _effectiveClientDirectives<FieldNode>(node, (n) => n.directives),
      alias: visitOne(node.alias),
      arguments: visitAll(node.arguments),
      selectionSet: visitOne(node.selectionSet),
    );
  }

  @override
  FragmentSpreadNode visitFragmentSpreadNode(FragmentSpreadNode node) {
    return FragmentSpreadNode(
      name: visitOne(node.name),
      directives: _effectiveClientDirectives<FragmentSpreadNode>(node, (n) => n.directives),
    );
  }

  @override
  InlineFragmentNode visitInlineFragmentNode(InlineFragmentNode node) {
    return InlineFragmentNode(
      directives: _effectiveClientDirectives<InlineFragmentNode>(node, (n) => n.directives),
      selectionSet: visitOne(node.selectionSet),
      typeCondition: visitOne(node.typeCondition),
    );
  }

  @override
  FragmentDefinitionNode visitFragmentDefinitionNode(FragmentDefinitionNode node) {
    return FragmentDefinitionNode(
      name: visitOne(node.name),
      directives: _effectiveClientDirectives<FragmentDefinitionNode>(node, (n) => n.directives),
      selectionSet: visitOne(node.selectionSet),
      typeCondition: visitOne(node.typeCondition),
    );
  }

  @override
  VariableDefinitionNode visitVariableDefinitionNode(VariableDefinitionNode node) {
    return VariableDefinitionNode(
      directives: _effectiveClientDirectives<VariableDefinitionNode>(node, (n) => n.directives),
      defaultValue: visitOne(node.defaultValue),
      type: visitOne(node.type),
      variable: visitOne(node.variable),
    );
  }

  @override
  EnumTypeDefinitionNode visitEnumTypeDefinitionNode(EnumTypeDefinitionNode node) {
    return EnumTypeDefinitionNode(
      name: visitOne(node.name),
      description: visitOne(node.description),
      directives: _effectiveClientDirectives<EnumTypeDefinitionNode>(node, (n) => n.directives),
      values: visitAll(node.values),
    );
  }

  @override
  UnionTypeDefinitionNode visitUnionTypeDefinitionNode(UnionTypeDefinitionNode node) {
    return UnionTypeDefinitionNode(
      name: visitOne(node.name),
      description: visitOne(node.description),
      directives: _effectiveClientDirectives<UnionTypeDefinitionNode>(node, (n) => n.directives),
      types: visitAll(node.types),
    );
  }

  @override
  ObjectTypeDefinitionNode visitObjectTypeDefinitionNode(ObjectTypeDefinitionNode node) {
    return ObjectTypeDefinitionNode(
      name: visitOne(node.name),
      description: visitOne(node.description),
      directives: _effectiveClientDirectives<ObjectTypeDefinitionNode>(node, (n) => n.directives),
      fields: visitAll(node.fields),
      interfaces: visitAll(node.interfaces),
    );
  }

  @override
  ScalarTypeDefinitionNode visitScalarTypeDefinitionNode(ScalarTypeDefinitionNode node) {
    return ScalarTypeDefinitionNode(
      name: visitOne(node.name),
      description: visitOne(node.description),
      directives: _effectiveClientDirectives<ScalarTypeDefinitionNode>(node, (n) => n.directives),
    );
  }

  @override
  InterfaceTypeDefinitionNode visitInterfaceTypeDefinitionNode(InterfaceTypeDefinitionNode node) {
    return InterfaceTypeDefinitionNode(
      name: visitOne(node.name),
      description: visitOne(node.description),
      directives:
          _effectiveClientDirectives<InterfaceTypeDefinitionNode>(node, (n) => n.directives),
      fields: visitAll(node.fields),
    );
  }

  @override
  InputObjectTypeDefinitionNode visitInputObjectTypeDefinitionNode(
      InputObjectTypeDefinitionNode node) {
    return InputObjectTypeDefinitionNode(
      name: visitOne(node.name),
      description: visitOne(node.description),
      directives:
          _effectiveClientDirectives<InputObjectTypeDefinitionNode>(node, (n) => n.directives),
      fields: visitAll(node.fields),
    );
  }

  @override
  EnumTypeExtensionNode visitEnumTypeExtensionNode(EnumTypeExtensionNode node) {
    return EnumTypeExtensionNode(
      name: visitOne(node.name),
      directives: _effectiveClientDirectives<EnumTypeExtensionNode>(node, (n) => n.directives),
      values: visitAll(node.values),
    );
  }

  @override
  UnionTypeExtensionNode visitUnionTypeExtensionNode(UnionTypeExtensionNode node) {
    return UnionTypeExtensionNode(
      name: visitOne(node.name),
      directives: _effectiveClientDirectives<UnionTypeExtensionNode>(node, (n) => n.directives),
      types: visitAll(node.types),
    );
  }

  @override
  ObjectTypeExtensionNode visitObjectTypeExtensionNode(ObjectTypeExtensionNode node) {
    return ObjectTypeExtensionNode(
      name: visitOne(node.name),
      directives: _effectiveClientDirectives<ObjectTypeExtensionNode>(node, (n) => n.directives),
      fields: visitAll(node.fields),
      interfaces: visitAll(node.interfaces),
    );
  }

  @override
  ScalarTypeExtensionNode visitScalarTypeExtensionNode(ScalarTypeExtensionNode node) {
    return ScalarTypeExtensionNode(
      name: visitOne(node.name),
      directives: _effectiveClientDirectives<ScalarTypeExtensionNode>(node, (n) => n.directives),
    );
  }

  @override
  InterfaceTypeExtensionNode visitInterfaceTypeExtensionNode(InterfaceTypeExtensionNode node) {
    return InterfaceTypeExtensionNode(
      name: visitOne(node.name),
      directives: _effectiveClientDirectives<InterfaceTypeExtensionNode>(node, (n) => n.directives),
      fields: visitAll(node.fields),
    );
  }

  @override
  InputObjectTypeExtensionNode visitInputObjectTypeExtensionNode(
      InputObjectTypeExtensionNode node) {
    return InputObjectTypeExtensionNode(
      name: visitOne(node.name),
      directives:
          _effectiveClientDirectives<InputObjectTypeExtensionNode>(node, (n) => n.directives),
      fields: visitAll(node.fields),
    );
  }

  @override
  FieldDefinitionNode visitFieldDefinitionNode(FieldDefinitionNode node) {
    return FieldDefinitionNode(
      name: visitOne(node.name),
      description: visitOne(node.description),
      directives: _effectiveClientDirectives<FieldDefinitionNode>(node, (n) => n.directives),
      args: visitAll(node.args),
      type: visitOne(node.type),
    );
  }

  @override
  InputValueDefinitionNode visitInputValueDefinitionNode(InputValueDefinitionNode node) {
    return InputValueDefinitionNode(
      name: visitOne(node.name),
      description: visitOne(node.description),
      directives: _effectiveClientDirectives<InputValueDefinitionNode>(node, (n) => n.directives),
      defaultValue: visitOne(node.defaultValue),
      type: visitOne(node.type),
    );
  }

  @override
  SchemaExtensionNode visitSchemaExtensionNode(SchemaExtensionNode node) {
    return SchemaExtensionNode(
      directives: _effectiveClientDirectives<SchemaExtensionNode>(node, (n) => n.directives),
      operationTypes: visitAll(node.operationTypes),
    );
  }
}
