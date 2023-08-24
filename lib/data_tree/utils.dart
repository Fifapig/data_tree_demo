import 'dart:math';

import 'package:flutter/material.dart';
import 'controller.dart';
import 'dart:ui' as ui;
import 'package:tuple/tuple.dart';

/// 存放计算相关方法
class CalculateUtils {
  /// 计算标题绘制参数
  ///
  /// `size` 画布大小
  /// `data` 中间标题信息
  static DataTree title(Size size, DataTree data) {
    /// 屏幕中点
    final center = Offset(size.width / 2.0, size.height / 2.0);

    final textSize =
        getTextSize(data.title, data.style, maxWidth: 120, maxLines: 2);

    final padding = data.textPadding;

    final rect = Rect.fromCenter(
        center: center,
        width: textSize.width + padding.horizontal,
        height: textSize.height + padding.vertical);

    // 更新值
    return data.copyWith(
      textSize: textSize,
      textBoxRect: rect,
      boxRect: rect,
    );
  }

  /// 计算叶子节点信息
  ///
  /// [superBoxRect] 父级模块列表的整体位置大小
  /// [superRect] 父级节点的大小
  // static Tuple2<Size, List<DataTree>> children(
  //   List<DataTree> data,
  //   Rect superBoxRect, {
  //   // 不传入默认和整个模块大小相同
  //   // Rect? superRect,
  //   bool isRight = true,
  // }) {
  //   if (data.isEmpty) return const Tuple2(Size.zero, []);

  //   // 整个树形结构的大小
  //   // 40 为默认横线长度
  //   // [_drawPointLine] 用于绘制横线
  //   // 10 为虚数 随便写的值，后续通过计算设置
  //   var boxSize = const Size(40, 0);

  //   // 设置基本位置
  //   List<DataTree> tempList = [];

  //   // 获取文本框大小，及带边线的大小
  //   for (var item in data) {
  //     final textSize = getTextSize(item.title, item.style ?? style20263A_14);

  //     item = item.copyWith(
  //       textSize: textSize,
  //       boxRect: Rect.fromLTWH(
  //         0,
  //         0,
  //         textSize.width + item.textPadding.horizontal + item.linePadding,
  //         textSize.height + item.textPadding.vertical + 12, // 12 为上下6px间隔
  //       ),
  //       textBoxRect: Rect.fromLTWH(
  //         0,
  //         0,
  //         textSize.width + item.textPadding.horizontal,
  //         textSize.height + item.textPadding.vertical,
  //       ),
  //     );

  //     // 更新整个树形结构的大小
  //     // 累加
  //     boxSize = boxSize.addHeight(item.boxRect.height);
  //     if (item.boxRect.width > boxSize.width) {
  //       // 更新
  //       boxSize = boxSize.updateWidth(item.boxRect.width);
  //     }

  //     tempList.add(item);
  //   }

  //   /// 整个树形结构的位置信息
  //   var boxRect = Rect.fromCenter(
  //     center: Offset(
  //         isRight
  //             ? superBoxRect.right + boxSize.width / 2
  //             : superBoxRect.left - boxSize.width / 2,
  //         superBoxRect.center.dy),
  //     width: boxSize.width,
  //     height: 0,
  //   );

  //   /// `boxSize` 通过计算已经得到列表`item`最宽宽度
  //   /// 由于`item`高度又由`children`的总体高度影响，所以需要复算一次`boxSize`获取到最新值
  //   for (var i = 0; i < tempList.length; i++) {
  //     var item = tempList[i];
  //     double height = item.boxRect.height;

  //     // 递归计算子集信息
  //     if (item.children.isNotEmpty) {
  //       final res = children(item.children, item.boxRect);
  //       height = max(height, res.item1.height);

  //       // 重新赋值高度
  //       boxRect = boxRect.addHeight(height);

  //       tempList[i] = item.copyWith(
  //         children: res.item2,
  //         boxRect: item.boxRect.updateHeight(height),
  //       );
  //     } else {
  //       boxRect = boxRect.addHeight(height);
  //     }
  //   }

  //   // 更新每一个数据的位置信息
  //   double height = 0;
  //   for (var i = 0; i < tempList.length; i++) {
  //     var item = tempList[i];
  //     final itemRect = Rect.fromLTWH(
  //         isRight ? boxRect.left + 40 : boxRect.right - item.boxRect.width - 40,
  //         boxRect.top + height,
  //         item.boxRect.width,
  //         item.boxRect.height);

  //     final itemTextRect = Rect.fromLTWH(
  //         isRight ? boxRect.left + 40 : boxRect.right - item.boxRect.width - 40,
  //         boxRect.top + height,
  //         item.textBoxRect.width,
  //         item.textBoxRect.height);

  //     tempList[i] = item.copyWith(
  //       boxRect: itemRect,
  //       textBoxRect: itemTextRect,
  //     );

  //     height += item.boxRect.height;
  //   }

  //   return Tuple2(boxRect.size, tempList);
  // }

  /// 优先计算所有元素的大小信息
  static Tuple2<Size, List<DataTree>> childrenSize(
    List<DataTree> data,
  ) {
    if (data.isEmpty) return const Tuple2(Size.zero, []);

    // 设置基本位置
    List<DataTree> tempList = [];
    var boxSize = const Size(40, 0);

    // 获取文本框大小，及带边线的大小
    for (var item in data) {
      final res = childrenSize(item.children);

      final textSize = getTextSize(item.title, item.style ?? textStyle);
      final textBoxHeight = textSize.height + item.textPadding.vertical + 12;
      item = item.copyWith(
        textSize: textSize,
        children: res.item2,
        boxRect: Rect.fromLTWH(
          0,
          0,
          textSize.width + item.textPadding.horizontal + item.linePadding,
          textBoxHeight, // 12 为上下6px间隔
        ),
        textBoxRect: Rect.fromLTWH(
          0,
          0,
          textSize.width + item.textPadding.horizontal,
          textSize.height + item.textPadding.vertical,
        ),
        childrenRect: Rect.fromLTWH(
          0,
          0,
          res.item1.width,
          max(textBoxHeight, res.item1.height),
        ),
      );

      // 更新整个树形结构的大小
      // 累加
      boxSize = boxSize.addHeight(max(item.boxRect.height, res.item1.height));
      if (item.boxRect.width > boxSize.width) {
        // 更新
        boxSize = boxSize.updateWidth(item.boxRect.width + 40);
      }

      tempList.add(item);
    }

    // 当前列总大小
    for (var i = 0; i < tempList.length; i++) {
      tempList[i] = tempList[i].copyWith(
        boxListRect: Rect.fromLTWH(
          0,
          0,
          boxSize.width,
          boxSize.height,
        ),
      );
    }

    return Tuple2(boxSize, tempList);
  }

  /// 继续计算所有元素的坐标信息
  ///
  /// [superBoxRect] 父级模块列表的整体位置大小
  /// [superRect] 父级节点的大小
  static List<DataTree> childrenRect(
    List<DataTree> data,
    Rect superBoxRect, {
    // 不传入默认和整个模块大小相同
    // 取中心坐标
    Rect? superRect,
    bool isRight = true,
  }) {
    if (data.isEmpty) return const [];

    const leftPadding = 40;
    final superRectTemp = superRect ?? superBoxRect;

    // 设置基本位置
    List<DataTree> tempList = List.of(data);

    final boxSize = data.first.boxListRect;

    /// 整个树形结构的位置信息
    var boxListRect = Rect.fromCenter(
      center: Offset(
          isRight
              ? superBoxRect.right + boxSize.width / 2
              : superBoxRect.left - boxSize.width / 2,
          superRectTemp.center.dy),
      width: boxSize.width,
      height: boxSize.height,
    );

    // 更新每一个数据的位置信息
    double height = 0;
    for (var i = 0; i < tempList.length; i++) {
      var item = tempList[i];
      final itemRect = Rect.fromLTWH(
          isRight
              ? boxListRect.left + leftPadding
              : boxListRect.right - item.boxRect.width - leftPadding,
          boxListRect.top + height,
          item.boxRect.width,
          item.childrenRect.height);

      final itemTextRect = Rect.fromLTWH(
          isRight
              ? boxListRect.left + leftPadding
              : boxListRect.right - item.boxRect.width - leftPadding,
          boxListRect.top + height,
          item.textBoxRect.width,
          item.textBoxRect.height);

      final childRect = Rect.fromLTWH(
          isRight
              ? boxListRect.left + leftPadding
              : boxListRect.right - item.boxRect.width - leftPadding,
          boxListRect.top + height,
          item.childrenRect.width,
          item.childrenRect.height);

      tempList[i] = item.copyWith(
        boxRect: itemRect,
        textBoxRect: itemTextRect,
        boxListRect: boxListRect,
        childrenRect: childRect,
      );

      if (item.children.isNotEmpty) {
        final res = childrenRect(
          item.children,
          boxListRect,
          superRect: childRect,
          isRight: isRight,
        );
        tempList[i] = tempList[i].copyWith(
          children: res,
        );
      }

      height += item.childrenRect.height;
    }

    return tempList;
  }

  /// 计算文本大小
  ///
  /// `text` 文本信息
  /// `style` 字体规格
  /// `maxLines` 行数
  /// `maxWidth` 绘制最大宽度
  static Size getTextSize(
    String text,
    TextStyle? style, {
    int? maxLines,
    double maxWidth = double.infinity,
  }) {
    TextPainter painter = TextPainter(
      // AUTO：华为手机如果不指定locale的时候，该方法算出来的文字高度是比系统计算偏小的。
      locale: WidgetsBinding.instance.window.locale,
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: text,
        style: style,
      ),
    );
    painter.layout(maxWidth: maxWidth);
    return painter.size;
  }
}

/// 绘制相关方法
class DrawUtils {
  /// 绘制文字
  ///
  /// `canvas` 画布
  /// `text`  文本内容
  /// `offset`  文本偏移（位置）
  /// `maxWith`  绘制最大宽度
  /// `maxLines`  行数
  /// `style`  字体规格
  /// `textAlign`  对齐方式
  /// `matrix`  形变值
  static text(
    Canvas canvas,
    String text,
    Offset offset, {
    // 文本宽度
    double maxWith = 120,
    int? maxLines = 2,
    TextStyle? style,
    TextAlign textAlign = TextAlign.center,
    Matrix4? matrix,
    String? ellipsis,
  }) {
    final newOffset = offset.transform(matrix);

    //  绘制文字
    var paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontFamily: style?.fontFamily,
        textAlign: textAlign,
        fontSize: (style?.fontSize ?? 14) * (matrix?.sacle ?? 1),
        fontWeight: style?.fontWeight,
        height: style?.height,
        maxLines: maxLines,
        ellipsis: ellipsis,
      ),
    );
    paragraphBuilder.pushStyle(ui.TextStyle(
        color: style?.color, textBaseline: ui.TextBaseline.alphabetic));
    paragraphBuilder.addText(text);
    var paragraph = paragraphBuilder.build();
    paragraph.layout(
        ui.ParagraphConstraints(width: maxWith * (matrix?.sacle ?? 1) + 2));
    canvas.drawParagraph(paragraph, Offset(newOffset.dx, newOffset.dy));
  }
}
