import 'package:flutter/material.dart';

const textStyle = TextStyle(fontSize: 16, color: Color(0xff20263A));
const titleStyle = TextStyle(fontSize: 16, color: Colors.white);

class Matrix4Animation extends ValueNotifier<Matrix4> {
  Matrix4Animation(super.value);
}

class DataTree {
  /// 下级列表
  final List<DataTree> children;

  /// 标题
  final String title;

  /// 当前item值
  final String value;

  /// 是否包含下级数据 显示 [⊕]
  final bool isMore;

  /// 位置信息
  final List<int> indexs;

  /// 携带原始数据结构，方便传值
  final dynamic data;

  /// 通过数据计算位置并记录
  /// rect 为整个模块信息（line+text+box)组合后
  ///
  /// `textBoxRect` + `linePadding`
  ///
  /// 记录当前标题框整体的坐标
  ///
  ///          `````````````````
  ///          `               `
  ///    ```````    文本内容    ``````
  ///          `               `
  ///          `````````````````
  ///
  final Rect boxRect;

  /// 记录列表标题框整体的坐标
  ///
  ///          `````````````````
  ///          `               `
  ///    ```````    文本内容    ``````
  ///          `               `
  ///          `````````````````
  ///          `````````````````
  ///          `               `
  ///    ```````    文本内容    ``````
  ///          `               `
  ///          `````````````````
  ///
  final Rect boxListRect;
  final Rect childrenRect;

  /// 包含textPadding的数据
  final Rect textBoxRect;
  final Size textSize;
  final EdgeInsets textPadding;

  /// 同级列表最大宽度 （计算当前子集与本身间隔线的距离）
  final double maxWidth;

  /// 文本大小
  final TextStyle? style;

  /// 文本框`textBoxRect`距离左右两边父级标签的距离
  /// 不包括`textSize.width`与`maxWidth`的间隔差值
  /// 所以绘制的时候需要额外补足该差值
  final double linePadding;

  /// 绘制轨迹（文本框体），用于命中交互
  /// 目前只保存文本框交互，如果需要额外交互则需要保存对应位置的信息
  final Path? path;

  /// 展开节点（显示图标过小，点击不太好响应，所以保存的时候增大响应区域
  // final Path? expandIconPath;

  DataTree(
    this.title, {
    this.value = '',
    this.isMore = false,
    this.data,
    this.boxRect = Rect.zero,
    this.boxListRect = Rect.zero,
    this.childrenRect = Rect.zero,
    this.textBoxRect = Rect.zero,
    this.textSize = Size.zero,
    this.textPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.linePadding = 22,
    this.children = const [],
    this.path,
    // this.expandIconPath,
    this.style,
    this.maxWidth = 0,
    this.indexs = const [],
  });

  DataTree copyWith({
    List<DataTree>? children,
    String? title,
    String? value,
    bool? isMore,
    dynamic data,
    Rect? boxRect,
    Rect? boxListRect,
    Rect? childrenRect,
    Rect? textBoxRect,
    Size? textSize,
    EdgeInsets? textPadding,
    double? linePadding,
    Path? path,
    // Path? expandIconPath,
    TextStyle? style,
    double? maxWidth,
    List<int>? indexs,
  }) {
    return DataTree(
      title ?? this.title,
      value: value ?? this.value,
      children: children ?? this.children,
      isMore: isMore ?? this.isMore,
      data: data ?? this.data,
      boxRect: boxRect ?? this.boxRect,
      textBoxRect: textBoxRect ?? this.textBoxRect,
      textSize: textSize ?? this.textSize,
      textPadding: textPadding ?? this.textPadding,
      linePadding: linePadding ?? this.linePadding,
      path: path ?? this.path,
      // expandIconPath: expandIconPath ?? this.expandIconPath,
      style: style ?? this.style,
      maxWidth: maxWidth ?? this.maxWidth,
      boxListRect: boxListRect ?? this.boxListRect,
      childrenRect: childrenRect ?? this.childrenRect,
      indexs: indexs ?? this.indexs,
    );
  }
}

extension RectEx on Rect {
  Rect addWidth(double value) {
    return Rect.fromCenter(
        center: center, width: width + value, height: height);
  }

  Rect fetchLeft(double value) {
    return Rect.fromLTWH(left - value, top, width + value, height);
  }

  Rect fetchRight(double value) {
    return Rect.fromLTWH(left, top, width + value, height);
  }

  Rect addHeight(double value) {
    return Rect.fromCenter(
        center: center, width: width, height: height + value);
  }

  Rect updateHeight(double value) {
    return Rect.fromCenter(center: center, width: width, height: value);
  }

  Rect transform(Matrix4? matrix) {
    if (matrix == null) return this;
    final translate = matrix.getTranslation();
    return Rect.fromLTWH(left + translate.x, top + translate.y, width, height);
  }
}

extension SizeEx on Size {
  Size addHeight(double value) {
    return Size(width, height + value);
  }

  Size addWidth(double value) {
    return Size(width + value, height);
  }

  Size updateWidth(double value) {
    return Size(value, height);
  }

  Size updateHeight(double value) {
    return Size(width, value);
  }
}

extension OffsetEx on Offset {
  Offset transform(Matrix4? matrix) {
    if (matrix == null) return this;
    final translate = matrix.getTranslation();
    final scale = matrix.sacle;

    return Offset(dx * scale + translate.x, dy * scale + translate.y);
  }
}

extension Matrix4Ex on Matrix4 {
  double get sacle {
    return this[0];
  }
}

List<DataTree> dataTreeIndexItems(List<DataTree> data,
    {List<int> sidx = const []}) {
  List<DataTree> tempList = [];
  for (var i = 0; i < data.length; i++) {
    var indexs = List.of(sidx);
    var item = data[i];
    indexs.addAll([i]);
    List<DataTree>? children;
    if (item.children.isNotEmpty) {
      children = dataTreeIndexItems(item.children, sidx: indexs);
    }
    item = item.copyWith(indexs: indexs, children: children);
    tempList.add(item);
  }
  return tempList;
}

extension ListEx on List<DataTree> {}
