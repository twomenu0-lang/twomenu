class ProductAttribute {
  List<Attribute>? attribute;
  List<Categories>? categories;

  ProductAttribute({this.attribute, this.categories});

  ProductAttribute.fromJson(Map<String, dynamic> json) {
    if (json['attribute'] != null) {
      attribute = <Attribute>[];
      json['attribute'].forEach((v) {
        attribute!.add(Attribute.fromJson(v));
      });
    }
    if (json['categories'] != null) {
      categories = <Categories>[];
      json['categories'].forEach((v) {
        categories!.add(Categories.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (attribute != null) {
      data['attribute'] = attribute!.map((v) => v.toJson()).toList();
    }
    if (categories != null) {
      data['categories'] = categories!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Attribute {
  String? id;
  String? name;
  String? slug;
  String? type;
  String? orderBy;
  int? hasArchives;
  int? total;
  List<Terms>? terms;

  Attribute({this.id, this.name, this.slug, this.type, this.orderBy, this.hasArchives, this.terms,this.total});

  Attribute.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    slug = json['slug'];
    type = json['type'];
    orderBy = json['order_by'];
    total = json['total'];
    hasArchives = json['has_archives'];
    if (json['terms'] != null) {
      terms = <Terms>[];
      json['terms'].forEach((v) {
        terms!.add(Terms.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    data['type'] = type;
    data['order_by'] = orderBy;
    data['has_archives'] = hasArchives;
    data['total'] = total;
    if (terms != null) {
      data['terms'] = terms!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Terms {
  int? termId;
  String? name;
  String? slug;
  int? termGroup;
  int? termTaxonomyId;
  String? taxonomy;
  String? description;
  int? parent;
  int? count;
  String? filter;
  bool? isParent = false;
  bool? isSelected = false;

  Terms({this.termId, this.name, this.slug, this.termGroup, this.termTaxonomyId, this.taxonomy, this.description, this.parent, this.count, this.filter, this.isSelected, this.isParent});

  Terms.fromJson(Map<String, dynamic> json) {
    termId = json['term_id'];
    name = json['name'];
    slug = json['slug'];
    termGroup = json['term_group'];
    termTaxonomyId = json['term_taxonomy_id'];
    taxonomy = json['taxonomy'];
    description = json['description'];
    parent = json['parent'];
    count = json['count'];
    filter = json['filter'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['term_id'] = termId;
    data['name'] = name;
    data['slug'] = slug;
    data['term_group'] = termGroup;
    data['term_taxonomy_id'] = termTaxonomyId;
    data['taxonomy'] = taxonomy;
    data['description'] = description;
    data['parent'] = parent;
    data['count'] = count;
    data['filter'] = filter;
    return data;
  }
}

class Categories {
  int? termId;
  String? name;
  String? slug;
  int? termGroup;
  int? termTaxonomyId;
  String? taxonomy;
  String? description;
  int? parent;
  int? count;
  String? filter;
  int? catID;
  int? categoryCount;
  String? categoryDescription;
  String? catName;
  String? categoryNicename;
  int? categoryParent;
  List<SubCategories>? subCategories;

  Categories(
      {this.termId,
      this.name,
      this.slug,
      this.termGroup,
      this.termTaxonomyId,
      this.taxonomy,
      this.description,
      this.parent,
      this.count,
      this.filter,
      this.catID,
      this.categoryCount,
      this.categoryDescription,
      this.catName,
      this.categoryNicename,
      this.categoryParent,
      this.subCategories});

  Categories.fromJson(Map<String, dynamic> json) {
    termId = json['term_id'];
    name = json['name'];
    slug = json['slug'];
    termGroup = json['term_group'];
    termTaxonomyId = json['term_taxonomy_id'];
    taxonomy = json['taxonomy'];
    description = json['description'];
    parent = json['parent'];
    count = json['count'];
    filter = json['filter'];
    catID = json['cat_ID'];
    categoryCount = json['category_count'];
    categoryDescription = json['category_description'];
    catName = json['cat_name'];
    categoryNicename = json['category_nicename'];
    categoryParent = json['category_parent'];
    if (json['sub_categories'] != null) {
      subCategories = <SubCategories>[];
      json['sub_categories'].forEach((v) {
        subCategories!.add(SubCategories.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['term_id'] = termId;
    data['name'] = name;
    data['slug'] = slug;
    data['term_group'] = termGroup;
    data['term_taxonomy_id'] = termTaxonomyId;
    data['taxonomy'] = taxonomy;
    data['description'] = description;
    data['parent'] = parent;
    data['count'] = count;
    data['filter'] = filter;
    data['cat_ID'] = catID;
    data['category_count'] = categoryCount;
    data['category_description'] = categoryDescription;
    data['cat_name'] = catName;
    data['category_nicename'] = categoryNicename;
    data['category_parent'] = categoryParent;
    if (subCategories != null) {
      data['sub_categories'] = subCategories!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SubCategories {
  int? termId;
  String? name;
  String? slug;
  int? termGroup;
  int? termTaxonomyId;
  String? taxonomy;
  String? description;
  int? parent;
  int? count;
  String? filter;
  int? catID;
  int? categoryCount;
  String? categoryDescription;
  String? catName;
  String? categoryNicename;
  int? categoryParent;

  SubCategories(
      {this.termId,
      this.name,
      this.slug,
      this.termGroup,
      this.termTaxonomyId,
      this.taxonomy,
      this.description,
      this.parent,
      this.count,
      this.filter,
      this.catID,
      this.categoryCount,
      this.categoryDescription,
      this.catName,
      this.categoryNicename,
      this.categoryParent});

  SubCategories.fromJson(Map<String, dynamic> json) {
    termId = json['term_id'];
    name = json['name'];
    slug = json['slug'];
    termGroup = json['term_group'];
    termTaxonomyId = json['term_taxonomy_id'];
    taxonomy = json['taxonomy'];
    description = json['description'];
    parent = json['parent'];
    count = json['count'];
    filter = json['filter'];
    catID = json['cat_ID'];
    categoryCount = json['category_count'];
    categoryDescription = json['category_description'];
    catName = json['cat_name'];
    categoryNicename = json['category_nicename'];
    categoryParent = json['category_parent'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['term_id'] = termId;
    data['name'] = name;
    data['slug'] = slug;
    data['term_group'] = termGroup;
    data['term_taxonomy_id'] = termTaxonomyId;
    data['taxonomy'] = taxonomy;
    data['description'] = description;
    data['parent'] = parent;
    data['count'] = count;
    data['filter'] = filter;
    data['cat_ID'] = catID;
    data['category_count'] = categoryCount;
    data['category_description'] = categoryDescription;
    data['cat_name'] = catName;
    data['category_nicename'] = categoryNicename;
    data['category_parent'] = categoryParent;
    return data;
  }
}

