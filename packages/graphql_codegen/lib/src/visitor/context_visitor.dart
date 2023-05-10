import 'package:gql/ast.dart';
import 'package:graphql_codegen/src/errors.dart';
import 'package:graphql_codegen/src/context.dart';

class ContextVisitor extends RecursiveVisitor {
  final Context context;

  ContextVisitor({required this.context});

  @override
  void visitVariableDefinitionNode(VariableDefinitionNode node) {
    final typeNodeForField = node.type;
    final fieldType = context.schema.lookupTypeDefinitionFromTypeNode(typeNodeForField);

    if (fieldType == null) {
      throw InvalidGraphQLDocumentError(
        "Failed to find type-definition for variable ${node.variable.name.value}",
      );
    }
    Name? path = null;
    if (fieldType is InputObjectTypeDefinitionNode) {
      path = Name.fromSegment(InputNameSegment(fieldType));
    }
    if (fieldType is EnumTypeDefinitionNode) {
      path = Name.fromSegment(EnumNameSegment(fieldType));
    }
    context.addVariable(
      ContextProperty.fromVariableDefinitionNode(
        node,
        path: path,
      ),
    );
  }

  @override
  void visitInputObjectTypeDefinitionNode(InputObjectTypeDefinitionNode node) {
    final c = context.withInput(node);
    node.visitChildren(ContextVisitor(context: c));
  }

  @override
  void visitInputValueDefinitionNode(InputValueDefinitionNode node) {
    final typeNodeForField = node.type;
    final fieldType = context.schema.lookupTypeDefinitionFromTypeNode(
      typeNodeForField,
    );

    if (fieldType == null) {
      throw InvalidGraphQLDocumentError(
        "Failed to find type-definition for field ${node.name.value}",
      );
    }

    if (fieldType is InputObjectTypeDefinitionNode) {
      context.addProperty(
        ContextProperty.fromInputValueDefinitionNode(
          node,
          path: Name.fromSegment(InputNameSegment(fieldType)),
        ),
      );
    } else if (fieldType is EnumTypeDefinitionNode) {
      context.addProperty(
        ContextProperty.fromInputValueDefinitionNode(
          node,
          path: Name.fromSegment(EnumNameSegment(fieldType)),
        ),
      );
    } else {
      context.addProperty(ContextProperty.fromInputValueDefinitionNode(node));
    }
  }

  @override
  void visitEnumTypeDefinitionNode(EnumTypeDefinitionNode node) {
    context.withEnum(node);
  }

  @override
  void visitFragmentDefinitionNode(FragmentDefinitionNode node) {
    final type = context.schema.lookupTypeDefinitionFromTypeNode(
      node.typeCondition.on,
    );
    if (type == null) {
      throw InvalidGraphQLDocumentError(
        "Failed to find type ${node.typeCondition.on.name.value} for fragment ${node.name.value}",
      );
    }
    final c = context.withFragmentAndType(node, type);
    node.visitChildren(ContextVisitor(context: c));
  }

  @override
  void visitOperationDefinitionNode(OperationDefinitionNode node) {
    final typeNode = context.schema.lookupOperationType(node.type);
    if (typeNode == null) {
      throw InvalidGraphQLDocumentError("Failed to find operation type for ${node.type}");
    }
    node.visitChildren(
      ContextVisitor(
        context: context.withOperationAndType(node, typeNode),
      ),
    );
  }

  void _visitInFragment(FragmentDefinitionNode node, Name name) {
    context.visitInFragment(
      name,
      () {
        node.selectionSet.visitChildren(this);
        context.addFragmentsFromInFragment();
      },
    );
    context.addFragment(name);
  }

  @override
  void visitFragmentSpreadNode(FragmentSpreadNode node) {
    final fragmentDef = context.schema.lookupFragmentEnforced(node.name);

    // Mark the context dependent on this fragment.
    context.addFragmentDependency(fragmentDef);

    final fragmentName = Name.fromSegment(FragmentNameSegment(fragmentDef));

    // Lookup the `ContextFragment` of the current fragment.
    // If it doesn't exists, create it!
    Context tempFragmentContext;
    if (context.hasContextFragment(fragmentName)) {
      tempFragmentContext = context;
    } else {
      tempFragmentContext = context.rootContext();
      ContextVisitor(context: tempFragmentContext).visitFragmentDefinitionNode(fragmentDef);
    }

    // If the fragment type condition exactly matches the current type,
    // inline the fragment directly.
    if (fragmentDef.typeCondition.on.name == context.currentType.name) {
      // Visiting "in-fragment" means that we'll expand the selection
      // set of the fragment while marking the current fragment name.
      // This'll help us derive the right interfaces.
      _visitInFragment(fragmentDef, fragmentName);
      return;
    }

    // Current type condition
    final typeCondition = fragmentDef.typeCondition;

    // Find concrete types of the type conditions.
    final typeConditionConcreteTypes =
        context.schema.lookupConcreteTypes(typeCondition.on.name).map((e) => e.name).toSet();

    // Find concrete types of the current type.
    final currentTypeConcreteTypes =
        context.schema.lookupConcreteTypes(context.currentType.name).map((e) => e.name).toSet();

    // Look-up the intersection of concrete types.
    final concreteIntersection = typeConditionConcreteTypes.intersection(currentTypeConcreteTypes);

    // If there's no intersection, return.
    if (concreteIntersection.isEmpty) {
      return;
    }

    // At this point, if the current type is an object, the intersection
    // will be exactly one.
    if (context.currentType is ObjectTypeDefinitionNode) {
      final typedFragmentName = fragmentName.withSegment(
        TypeNameSegment(context.currentType.name),
      );
      // If a fragment context with the current type as type condition
      // exists, we'll visit the fragment of this instead of the
      // general fragment.
      //
      // This happens when a fragment is on an abstract type but has
      // itself a fragment spread on the relevant concrete type.
      final existingFragmentName = tempFragmentContext.contextFragmentNameOrFallback(
        typedFragmentName,
        fragmentName,
      );
      _visitInFragment(fragmentDef, existingFragmentName);
      return;
    }

    // We'll now go through each concrete type in the type intersection and
    // create a typed context.
    for (final typeName in concreteIntersection) {
      final typeNode = context.schema.lookupType(typeName);
      if (typeNode == null) {
        throw InvalidGraphQLDocumentError("Failed to find definition for type ${typeName.value}");
      }
      final typedFragmentName = fragmentName.withSegment(
        TypeNameSegment(typeName),
      );

      final existingFragmentName = tempFragmentContext.contextFragmentNameOrFallback(
        typedFragmentName,
        fragmentName,
      );

      final c = context.withNameAndType(
        TypeNameSegment(typeName),
        typeNode,
        extendsName: context.path,
        inFragment: existingFragmentName,
      );
      fragmentDef.visitChildren(
        ContextVisitor(context: c),
      );
      context.addPossibleTypeName(c);
    }
  }

  @override
  void visitSelectionSetNode(SelectionSetNode node) {
    node.visitChildren(this);
    context.addFragmentsFromInFragment();
    context.addSelectionSet(node);
  }

  @override
  void visitInlineFragmentNode(InlineFragmentNode node) {
    final typeCondition = node.typeCondition;
    // If we do not have a type condition, inline the selection set.
    // TODO support directives
    if (typeCondition == null || typeCondition.on.name == context.currentType.name) {
      node.selectionSet.visitChildren(this);
      return;
    }

    final typeConditionConcreteTypes =
        context.schema.lookupConcreteTypes(typeCondition.on.name).map((e) => e.name).toSet();
    final currentTypeConcreteTypes =
        context.schema.lookupConcreteTypes(context.currentType.name).map((e) => e.name).toSet();

    final concreteIntersection = typeConditionConcreteTypes.intersection(currentTypeConcreteTypes);

    if (concreteIntersection.isEmpty) {
      return;
    }

    if (context.currentType is ObjectTypeDefinitionNode) {
      node.selectionSet.visitChildren(this);
      return;
    }

    for (final typeName in concreteIntersection) {
      final typeNode = context.schema.lookupType(typeName);
      if (typeNode == null) {
        throw InvalidGraphQLDocumentError("Failed to find definition for type ${typeName.value}");
      }
      final c = context.withNameAndType(
        TypeNameSegment(typeNode.name),
        typeNode,
        extendsName: context.path,
      );
      node.visitChildren(
        ContextVisitor(
          context: c,
        ),
      );
      context.addPossibleTypeName(c);
    }
  }

  @override
  void visitFieldNode(FieldNode node) {
    final currentType = context.currentType;
    final typeNodeForField = context.schema.lookupTypeNodeFromField(
      currentType,
      node.name,
    );
    if (typeNodeForField == null) {
      throw InvalidGraphQLDocumentError(
        "Failed to find type for field ${node.name.value} on ${currentType.name.value}",
      );
    }
    final fieldType = context.schema.lookupTypeDefinitionFromTypeNode(
      typeNodeForField,
    );

    if (fieldType == null) {
      throw InvalidGraphQLDocumentError(
        "Failed to find type-definition for field ${node.name.value} on ${currentType.name.value}",
      );
    }

    if (fieldType is ObjectTypeDefinitionNode ||
        fieldType is InterfaceTypeDefinitionNode ||
        fieldType is UnionTypeDefinitionNode) {
      final segment = FieldNameSegment(node);
      final c = context.withNameAndType(
        segment,
        fieldType,
        extendsName: context.extendsName?.withSegment(segment),
      );
      node.visitChildren(ContextVisitor(context: c));
      context.addProperty(ContextProperty.fromFieldNode(
        node,
        path: c.path,
        type: typeNodeForField,
      ));
    } else if (fieldType is EnumTypeDefinitionNode) {
      context.addProperty(
        ContextProperty.fromFieldNode(
          node,
          path: Name.fromSegment(EnumNameSegment(fieldType)),
          type: typeNodeForField,
        ),
      );
    } else {
      context.addProperty(ContextProperty.fromFieldNode(
        node,
        type: typeNodeForField,
      ));
    }

    for (final argument in node.arguments) {
      final argumentType = context.schema.lookupTypeNodeForArgument(
        context.currentType,
        node.name,
        argument,
      );
      if (argumentType == null) {
        throw InvalidGraphQLDocumentError(
          "Failed to find type for argument ${argument.name.value} on field ${node.name.value} on type ${currentType.name.value}",
        );
      }
      context.addArgument(argument.value, argumentType);
    }
  }
}
