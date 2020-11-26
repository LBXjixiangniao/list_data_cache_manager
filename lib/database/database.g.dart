// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class CacheDBItem extends DataClass implements Insertable<CacheDBItem> {
  final int index;
  final String content;
  final String type;
  CacheDBItem(
      {@required this.index, @required this.content, @required this.type});
  factory CacheDBItem.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    return CacheDBItem(
      index: intType.mapFromDatabaseResponse(data['${effectivePrefix}index']),
      content:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}content']),
      type: stringType.mapFromDatabaseResponse(data['${effectivePrefix}type']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || index != null) {
      map['index'] = Variable<int>(index);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    return map;
  }

  CacheDBItemsCompanion toCompanion(bool nullToAbsent) {
    return CacheDBItemsCompanion(
      index:
          index == null && nullToAbsent ? const Value.absent() : Value(index),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
    );
  }

  factory CacheDBItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return CacheDBItem(
      index: serializer.fromJson<int>(json['index']),
      content: serializer.fromJson<String>(json['content']),
      type: serializer.fromJson<String>(json['type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'index': serializer.toJson<int>(index),
      'content': serializer.toJson<String>(content),
      'type': serializer.toJson<String>(type),
    };
  }

  CacheDBItem copyWith({int index, String content, String type}) => CacheDBItem(
        index: index ?? this.index,
        content: content ?? this.content,
        type: type ?? this.type,
      );
  @override
  String toString() {
    return (StringBuffer('CacheDBItem(')
          ..write('index: $index, ')
          ..write('content: $content, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      $mrjf($mrjc(index.hashCode, $mrjc(content.hashCode, type.hashCode)));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is CacheDBItem &&
          other.index == this.index &&
          other.content == this.content &&
          other.type == this.type);
}

class CacheDBItemsCompanion extends UpdateCompanion<CacheDBItem> {
  final Value<int> index;
  final Value<String> content;
  final Value<String> type;
  const CacheDBItemsCompanion({
    this.index = const Value.absent(),
    this.content = const Value.absent(),
    this.type = const Value.absent(),
  });
  CacheDBItemsCompanion.insert({
    this.index = const Value.absent(),
    @required String content,
    @required String type,
  })  : content = Value(content),
        type = Value(type);
  static Insertable<CacheDBItem> custom({
    Expression<int> index,
    Expression<String> content,
    Expression<String> type,
  }) {
    return RawValuesInsertable({
      if (index != null) 'index': index,
      if (content != null) 'content': content,
      if (type != null) 'type': type,
    });
  }

  CacheDBItemsCompanion copyWith(
      {Value<int> index, Value<String> content, Value<String> type}) {
    return CacheDBItemsCompanion(
      index: index ?? this.index,
      content: content ?? this.content,
      type: type ?? this.type,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (index.present) {
      map['index'] = Variable<int>(index.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheDBItemsCompanion(')
          ..write('index: $index, ')
          ..write('content: $content, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }
}

class $CacheDBItemsTable extends CacheDBItems
    with TableInfo<$CacheDBItemsTable, CacheDBItem> {
  final GeneratedDatabase _db;
  final String _alias;
  $CacheDBItemsTable(this._db, [this._alias]);
  final VerificationMeta _indexMeta = const VerificationMeta('index');
  GeneratedIntColumn _index;
  @override
  GeneratedIntColumn get index => _index ??= _constructIndex();
  GeneratedIntColumn _constructIndex() {
    return GeneratedIntColumn(
      'index',
      $tableName,
      false,
    );
  }

  final VerificationMeta _contentMeta = const VerificationMeta('content');
  GeneratedTextColumn _content;
  @override
  GeneratedTextColumn get content => _content ??= _constructContent();
  GeneratedTextColumn _constructContent() {
    return GeneratedTextColumn(
      'content',
      $tableName,
      false,
    );
  }

  final VerificationMeta _typeMeta = const VerificationMeta('type');
  GeneratedTextColumn _type;
  @override
  GeneratedTextColumn get type => _type ??= _constructType();
  GeneratedTextColumn _constructType() {
    return GeneratedTextColumn(
      'type',
      $tableName,
      false,
    );
  }

  @override
  List<GeneratedColumn> get $columns => [index, content, type];
  @override
  $CacheDBItemsTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'cache_d_b_items';
  @override
  final String actualTableName = 'cache_d_b_items';
  @override
  VerificationContext validateIntegrity(Insertable<CacheDBItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('index')) {
      context.handle(
          _indexMeta, index.isAcceptableOrUnknown(data['index'], _indexMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content'], _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type'], _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {index};
  @override
  CacheDBItem map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return CacheDBItem.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  $CacheDBItemsTable createAlias(String alias) {
    return $CacheDBItemsTable(_db, alias);
  }
}

abstract class _$LbxDatabase extends GeneratedDatabase {
  _$LbxDatabase(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  _$LbxDatabase.connect(DatabaseConnection c) : super.connect(c);
  $CacheDBItemsTable _cacheDBItems;
  $CacheDBItemsTable get cacheDBItems =>
      _cacheDBItems ??= $CacheDBItemsTable(this);
  CacheDBItemsDao _cacheDBItemsDao;
  CacheDBItemsDao get cacheDBItemsDao =>
      _cacheDBItemsDao ??= CacheDBItemsDao(this as LbxDatabase);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [cacheDBItems];
}
