#!/usr/bin/env python3
"""
PDF转图片脚本
将PDF文档转换为PNG图片以便分析
"""

import fitz  # PyMuPDF
import os
import sys

def pdf_to_images(pdf_path, output_dir="pdf_images"):
    """将PDF转换为图片"""
    try:
        # 创建输出目录
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
        
        # 打开PDF文档
        doc = fitz.open(pdf_path)
        
        print(f"PDF包含 {len(doc)} 页")
        
        # 转换每一页
        for page_num in range(len(doc)):
            page = doc.load_page(page_num)
            
            # 设置缩放比例和旋转
            mat = fitz.Matrix(2.0, 2.0)  # 2倍缩放以提高清晰度
            pix = page.get_pixmap(matrix=mat)
            
            # 保存图片
            output_path = os.path.join(output_dir, f"page_{page_num + 1:02d}.png")
            pix.save(output_path)
            
            print(f"已转换第 {page_num + 1} 页: {output_path}")
        
        doc.close()
        print(f"\n转换完成！图片保存在: {output_dir}/")
        return True
        
    except Exception as e:
        print(f"转换失败: {e}")
        return False

if __name__ == "__main__":
    pdf_file = "Build Ecosystem Application VM Image.pdf"
    
    if os.path.exists(pdf_file):
        pdf_to_images(pdf_file)
    else:
        print(f"错误: 找不到PDF文件 {pdf_file}")
        sys.exit(1)