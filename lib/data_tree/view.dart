import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'controller.dart';
import 'utils.dart';
import 'matrix_gesture_detector.dart';

/// 点击回调
typedef DataTreeTapCallback = void Function(
    DataTree data, List<DataTree> items, List<int> indexs);

class DataTreeView extends StatefulWidget {
  /// 主方向树状图（→右）
  final List<DataTree> items;

  /// 扩展方向树状图（左←）
  final List<DataTree> extraItems;

  /// 中间标题
  final String title;

  /// 点击回调
  final DataTreeTapCallback? onItemsTap;

  /// 点击回调
  final DataTreeTapCallback? onExtraTap;

  const DataTreeView({
    super.key,
    this.items = const [],
    this.extraItems = const [],
    this.title = '--',
    this.onExtraTap,
    this.onItemsTap,
  });

  @override
  State<DataTreeView> createState() => _DataTreeViewState();
}

class _DataTreeViewState extends State<DataTreeView>
    with SingleTickerProviderStateMixin {
  /// 主方向树状图（→右）
  List<DataTree> _items = [];

  /// 扩展方向树状图（左←）
  List<DataTree> _extraItems = [];

  final Matrix4Animation _transform = Matrix4Animation(
    Matrix4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1),
  );

  @override
  void initState() {
    super.initState();

    // int length = tempList.length, levels = 1, count = 0;

    // String name = '天津明朗供应链管理有限公司3';

    // while (tempList.isNotEmpty) {
    //   final item = tempList.removeLast();
    //   if (item.title == name) {
    //     break;
    //   } else {
    //     tempList.addAll(item.children);
    //   }
    //   count++;
    //   if (count == length) {
    //     length = tempList.length;
    //     count = 0;
    //     levels++;
    //   }
    // }
  }

  DataTree? _checkTapPoint(Offset point, List<DataTree> paths) {
    DataTree? pathContains(List<DataTree> data) {
      for (var element in data) {
        final isContains = element.path?.contains(point);
        if (isContains == true) {
          print('onItemsTap: ${element.indexs}');
          return element;
        }

        // 查询下级
        if (element.children.isNotEmpty) {
          final res = pathContains(element.children);
          if (res != null) {
            return res;
          }
        }
      }
      return null;
    }

    return pathContains(paths);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return GestureDetector(
        onTapDown: (TapDownDetails details) {
          final point = details.globalPosition;
          if (_items.isNotEmpty) {
            final res = _checkTapPoint(point, _items);
            if (res != null) {
              widget.onItemsTap?.call(res, _items, res.indexs);
            }
          }
          if (_extraItems.isNotEmpty) {
            final res = _checkTapPoint(point, _extraItems);
            if (res != null) {
              widget.onExtraTap?.call(res, _extraItems, res.indexs);
            }
          }
        },
        child: MatrixGestureDetector(
          shouldRotate: false,
          onMatrixUpdate: (
            Matrix4 matrix,
            Matrix4 translationDeltaMatrix,
            Matrix4 scaleDeltaMatrix,
            Matrix4 rotationDeltaMatrix,
          ) {
            _transform.value = matrix;
          },
          child: RepaintBoundary(
            child: CustomPaint(
              painter: DataTreePainter(
                _transform,
                items: widget.items,
                extraItems: widget.extraItems,
                title: widget.title,
                drawComplete: (p0, p1) {
                  _items = p0;
                  _extraItems = p1;
                },
              ),
              size: Size(constraints.maxWidth, constraints.maxHeight),
            ),
          ),
        ),
      );
    });
  }
}

class DataTreePainter extends CustomPainter {
  final String title;

  /// 主方向树状图（→右）
  final List<DataTree> items;

  /// 扩展方向树状图（左←）
  final List<DataTree> extraItems;

  /// 绘制完成回调
  final void Function(List<DataTree> items, List<DataTree> extraItems)?
      drawComplete;

  final Matrix4Animation factor;

  DataTreePainter(
    this.factor, {
    this.items = const [],
    this.extraItems = const [],
    this.title = '-',
    this.drawComplete,
  }) : super(repaint: factor) {
    _title = DataTree(
      title,
      style: titleStyle.copyWith(height: 1.25),
      linePadding: 40,
    );
  }

  /// 记录中间标题信息
  late DataTree _title;

  /// 主方向树状图（→右）
  List<DataTree> _items = [];

  /// 扩展方向树状图（左←）
  List<DataTree> _extraItems = [];

  /// 展开图标
  // late ui.Image _expandIcon;

  @override
  void paint(Canvas canvas, Size size) {
    // 计算各项绘制参数（后续只需要直接绘制即可）
    _title = CalculateUtils.title(size, _title);
    _drawTitle(canvas, factor.value);

    if (items.isNotEmpty) {
      final resRight = CalculateUtils.childrenSize(items);
      _items = CalculateUtils.childrenRect(resRight.item2, _title.boxRect);
      _drawCompanyList(canvas, _items, _title.boxRect, factor.value);
    }

    if (extraItems.isNotEmpty) {
      final resLeft = CalculateUtils.childrenSize(extraItems);
      _extraItems = CalculateUtils.childrenRect(resLeft.item2, _title.boxRect,
          isRight: false);
      _drawCompanyList(canvas, _extraItems, _title.boxRect, factor.value,
          isRight: false);
    }

    // 绘制中间标题
    // _drawTitle(canvas, size, factor.value);

    // 绘制主方向树状图

    // 绘制扩展方向树状图
    // _drawCompanyList(canvas, extraItems, _title.boxRect, factor.value,
    // isRight: false);

    //
    // SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
    drawComplete?.call(_items, _extraItems);
    // });
  }

  /// 绘制数据列表
  ///
  /// `canvas` 画布
  /// `data` 数据列表
  /// `superBoxRect` 上级树形结构的大小
  /// `matrix` 手势变换矩阵
  /// `isRight` 树形结构延伸方向
  _drawCompanyList(
      Canvas canvas, List<DataTree> data, Rect superBoxRect, Matrix4 matrix,
      {bool isRight = true}) {
    // if (data.isEmpty) return Size.zero;
    // print('---------------- _drawCompanyList');
    // // 整个树形结构的大小
    // // 40 为默认横线长度
    // // [_drawPointLine] 用于绘制横线
    // var boxSize = const Size(40, 0);

    // // 设置基本位置
    // List<DataTree> tempList = [];
    // for (var item in data) {
    //   final textSize = CalculateUtils.getTextSize(item.title, style20263A_14);
    //   //  添加下级绘制信息
    //   // if (item.children.isNotEmpty) {
    //   //   final childBox = _drawCompanyList(canvas, data, superBoxRect, matrix);
    //   //   boxSize = boxSize.fetchHeight(childBox.height);
    //   // }

    //   item = item.copyWith(
    //     textSize: textSize,
    //     boxRect: Rect.fromLTWH(
    //       0,
    //       0,
    //       textSize.width + item.textPadding.horizontal + item.linePadding,
    //       textSize.height + item.textPadding.vertical + 12,
    //     ),
    //     textBoxRect: Rect.fromLTWH(
    //       0,
    //       0,
    //       textSize.width + item.textPadding.horizontal,
    //       textSize.height + item.textPadding.vertical,
    //     ),
    //   );

    //   // 更新整个树形结构的大小
    //   boxSize = boxSize.addHeight(item.boxRect.height);
    //   if (item.boxRect.width > boxSize.width) {
    //     boxSize = boxSize.addWidth(item.boxRect.width);
    //   }

    //   tempList.add(item);
    // }

    // // 整个树形结构的位置信息
    // final boxRect = Rect.fromCenter(
    //   center: Offset(
    //       isRight
    //           ? superBoxRect.right + boxSize.width / 2
    //           : superBoxRect.left - boxSize.width / 2,
    //       superBoxRect.center.dy),
    //   width: boxSize.width,
    //   height: boxSize.height,
    // );

    // // 更新每一个数据的位置信息
    // for (var i = 0; i < tempList.length; i++) {
    //   var item = tempList[i];
    //   final itemRect = Rect.fromLTWH(
    //       isRight ? boxRect.left + 40 : boxRect.right - item.boxRect.width - 40,
    //       boxRect.top + item.boxRect.height * i,
    //       item.boxRect.width,
    //       item.boxRect.height);
    //   final itemTextRect = Rect.fromLTWH(
    //       isRight ? boxRect.left + 40 : boxRect.right - item.boxRect.width - 40,
    //       boxRect.top + item.boxRect.height * i,
    //       item.textBoxRect.width,
    //       item.textBoxRect.height);
    //   tempList[i] = item.copyWith(
    //     boxRect: itemRect,
    //     textBoxRect: itemTextRect,
    //   );
    // }

    for (var i = 0; i < data.length; i++) {
      final item = data[i];
      _drawItemBox(canvas, data, i, matrix, isRight: isRight);
      if (item.children.isNotEmpty) {
        _drawCompanyList(canvas, item.children, item.boxRect, factor.value,
            isRight: isRight);
      }
    }

    // 横线
    _drawPointLine(canvas, data.first, superBoxRect, matrix, isRight);

    /// 保存计算后的列表数据
    // if (isRight) {
    //   _items = tempList;
    // } else {
    //   _extraItems = tempList;
    // }
    // return boxSize;
  }

  // 绘制中间标题
  _drawItemBox(Canvas canvas, List<DataTree> data, int index, Matrix4 matrix,
      {bool isRight = true}) {
    final flag = isRight ? 1 : -1;
    var item = data[index];

    /// 文本绘制中点
    final center = Offset(item.boxRect.center.dx + flag * item.linePadding / 2,
        item.boxRect.center.dy);

    final titleStyle = textStyle.copyWith(
      color: item.title.contains('更多') ? const Color(0xff1074E7) : null,
    );

    final textSize = item.textSize;

    // 背景
    final padding = item.textPadding;
    final rect = Rect.fromCenter(
        center: center,
        width: textSize.width + padding.horizontal,
        height: textSize.height + padding.vertical);

    final textPaint = Paint();

    var path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect,
          const Radius.circular(4),
        ),
      );

    path = path.transform(matrix.storage);

    textPaint.style = PaintingStyle.fill;
    textPaint.color = const Color(0xffF5F8FE);
    canvas.drawPath(path, textPaint);

    textPaint.style = PaintingStyle.stroke;
    textPaint.color = const Color(0xffE7ECF5);
    canvas.drawPath(path, textPaint);

    // 修改值
    data[index] = data[index].copyWith(path: path);

    // 文字
    DrawUtils.text(
      canvas,
      item.title,
      Offset(center.dx - textSize.width / 2, center.dy - textSize.height / 2),
      style: titleStyle,
      maxWith: textSize.width,
      matrix: matrix,
      maxLines: 1,
    );

    // 绘制结构图线条
    final linePaint = Paint();
    linePaint.strokeWidth = 1;
    linePaint.style = PaintingStyle.stroke;
    linePaint.color = const Color(0xff2A86F1);

    final linePath = Path();

    // 文本框边，重叠的竖线
    final dx = isRight ? rect.centerLeft.dx : rect.centerRight.dx;
    linePath.moveTo(dx, rect.center.dy - 4);
    linePath.lineTo(dx, rect.center.dy + 4);
    // canvas.drawPath(path, linePaint);

    // 横线间隔（不包含圆角=8的距离）
    linePath.moveTo(dx, rect.center.dy);
    linePath.lineTo(
        isRight ? dx - item.linePadding + 8 : dx + item.linePadding - 8,
        rect.center.dy);
    // canvas.drawPath(path, linePaint);

    /// 线条是否带圆角
    final isRaduis =
        (data.length >= 2 && (index == 0 || index == data.length - 1));

    if (isRaduis) {
      if (index == 0) {
        linePath.arcTo(
            Rect.fromLTWH(dx - flag * item.linePadding - (isRight ? 0 : 8),
                rect.center.dy, 8, 8),
            3 * pi / 2,
            -flag * pi / 2,
            false);
        linePath.lineTo(dx - flag * item.linePadding, item.boxRect.bottom);
      }
      if (index == data.length - 1) {
        linePath.arcTo(
            Rect.fromLTWH(dx - flag * item.linePadding - (isRight ? 0 : 8),
                rect.center.dy - 8, 8, 8),
            pi / 2,
            flag * pi / 2,
            false);
        linePath.lineTo(dx - flag * item.linePadding, item.boxRect.top);
      }
    } else {
      linePath.lineTo(dx - flag * item.linePadding, item.boxRect.center.dy);
      if (data.length > 1) {
        linePath.moveTo(dx - flag * item.linePadding, item.boxRect.top);
        linePath.lineTo(dx - flag * item.linePadding, item.boxRect.bottom);
      }
    }
    canvas.drawPath(linePath.transform(matrix.storage), linePaint);

    // 绘制展开图标
    if (item.isMore && item.children.isEmpty) {
      _drawExpandIcon(canvas, item.boxRect, matrix, isRight);
    }
  }

  _drawExpandIcon(Canvas canvas, Rect boxRect, Matrix4 matrix, bool isRight) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xff2A86F1);

    final dx = isRight ? boxRect.right : boxRect.left;

    final path = Path()
      ..addOval(
        Rect.fromCenter(
            center: Offset(dx, boxRect.center.dy), width: 10, height: 10),
      );

    canvas.drawPath(path.transform(matrix.storage), paint);

    final paint2 = Paint();
    paint2.color = Colors.white;
    paint2.style = PaintingStyle.stroke;
    paint2.strokeWidth = 1;

    // 横线
    final path2 = Path();
    path2.moveTo(dx + 2, boxRect.center.dy);
    path2.lineTo(dx - 2, boxRect.center.dy);
    canvas.drawPath(path2.transform(matrix.storage), paint2);

    path2.moveTo(dx, boxRect.center.dy + 2);
    path2.lineTo(dx, boxRect.center.dy - 2);
    canvas.drawPath(path2.transform(matrix.storage), paint2);
  }

  /// 绘制列表模块 距离父级模块的 圆点横线
  ///         |
  ///   O-----|------
  ///         |
  /// 
  /// 
  ///         |
  ///   ------|-----O
  ///         |
  /// 
  _drawPointLine(Canvas canvas, DataTree item, Rect superBoxRect,
      Matrix4 matrix, bool isRight) {
    final boxRect = item.boxListRect;

    // 左右间隔线
    final linePaint = Paint();
    linePaint.strokeWidth = 1;

    final path = Path();

    path.moveTo(
        isRight ? superBoxRect.centerRight.dx : superBoxRect.centerLeft.dx,
        superBoxRect.center.dy);
    path.addArc(
        Rect.fromLTWH(
            (isRight
                    ? superBoxRect.centerRight.dx
                    : superBoxRect.centerLeft.dx) -
                2,
            superBoxRect.center.dy - 2,
            4,
            4),
        isRight ? 0 : pi,
        2 * pi);
    linePaint.style = PaintingStyle.fill;
    linePaint.color = Colors.white;
    canvas.drawPath(path.transform(matrix.storage), linePaint);

    path.lineTo(
        isRight ? boxRect.centerLeft.dx + 40 : boxRect.centerRight.dx - 40,
        boxRect.center.dy);

    linePaint.style = PaintingStyle.stroke;
    linePaint.color = const Color(0xff2A86F1);
    canvas.drawPath(path.transform(matrix.storage), linePaint);
  }

  /// 计算标题绘制参数
  // _calculateTitle(Size size) {
  //   /// 记录总体大小
  //   Rect boxRect = Rect.zero;

  //   /// 屏幕中点
  //   final center = Offset(size.width / 2.0, size.height / 2.0);

  //   final titleStyle = styleMdFFFFFF_16.copyWith(height: 1.25);

  //   final textSize = TCalculate.getTextSize(title, titleStyle, maxWidth: 120);

  //   final padding = _title.textPadding;

  //   final rect = Rect.fromCenter(
  //       center: center,
  //       width: textSize.width + padding.left * 2,
  //       height: textSize.height + padding.top * 2);

  //   boxRect = rect;

  //   // if (items.isNotEmpty) {
  //   //   boxRect = boxRect.fetchRight(40);
  //   // }

  //   // if (extraItems.isNotEmpty) {
  //   //   boxRect = boxRect.fetchLeft(40);
  //   // }

  //   // 更新值
  //   _title = _title.copyWith(
  //     textSize: textSize,
  //     textBoxRect: rect,
  //     boxRect: boxRect,
  //   );
  // }

  // 绘制中间标题
  _drawTitle(
    Canvas canvas,
    Matrix4 matrix,
  ) {
    /// 屏幕中点
    final center = _title.textBoxRect.center;

    final titleStyle = _title.style;

    final textSize = _title.textSize;

    final rect = _title.textBoxRect;

    final textPaint = Paint();
    textPaint.style = PaintingStyle.fill;
    textPaint.shader = ui.Gradient.linear(
        Offset(rect.left, center.dy).transform(matrix),
        Offset(rect.right, center.dy).transform(matrix),
        [const Color(0xff53A2FF), const Color(0xff076EE4)]);

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect,
          const Radius.circular(4),
        ),
      );

    canvas.drawPath(path.transform(matrix.storage), textPaint);

    // 文字
    DrawUtils.text(
      canvas,
      title,
      Offset(rect.left + _title.textPadding.left,
          rect.top + _title.textPadding.top),
      style: titleStyle,
      maxWith: textSize.width,
      matrix: matrix,
      ellipsis: '...',
      // maxLines: 10,
    );

    // 左右间隔线
    // final linePaint = Paint();
    // linePaint.strokeWidth = 1;

    // 右间隔线
    // if (items.isNotEmpty) {
    //   final path = Path();
    //   path.moveTo(rect.centerRight.dx, rect.center.dy);
    //   path.addArc(
    //       Rect.fromLTWH(rect.centerRight.dx - 2, rect.center.dy - 2, 4, 4),
    //       0,
    //       2 * pi);
    //   linePaint.style = PaintingStyle.fill;
    //   linePaint.color = ColorConfig.colorFFFFFF;
    //   canvas.drawPath(path.transform(matrix.storage), linePaint);

    //   path.lineTo(rect.centerRight.dx + 40, rect.center.dy);
    //   linePaint.style = PaintingStyle.stroke;
    //   linePaint.color = ColorConfig.color2A86F1;
    //   canvas.drawPath(path.transform(matrix.storage), linePaint);
    // }
    // 左间隔线
    // if (extraItems.isNotEmpty) {
    //   final path = Path();
    //   path.moveTo(rect.centerLeft.dx, rect.center.dy);
    //   path.addArc(
    //       Rect.fromLTWH(rect.centerLeft.dx - 2, rect.center.dy - 2, 4, 4),
    //       pi,
    //       2 * pi);
    //   linePaint.style = PaintingStyle.fill;
    //   linePaint.color = ColorConfig.colorFFFFFF;
    //   canvas.drawPath(path.transform(matrix.storage), linePaint);

    //   path.lineTo(rect.centerLeft.dx - 40, rect.center.dy);
    //   linePaint.style = PaintingStyle.stroke;
    //   linePaint.color = ColorConfig.color2A86F1;
    //   canvas.drawPath(path.transform(matrix.storage), linePaint);
    // }
  }

  @override
  bool shouldRepaint(DataTreePainter oldDelegate) =>
      oldDelegate.items != items ||
      oldDelegate.extraItems != extraItems ||
      factor != oldDelegate.factor;

  @override
  bool shouldRebuildSemantics(DataTreePainter oldDelegate) => false;
}
