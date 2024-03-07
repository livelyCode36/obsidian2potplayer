#Requires AutoHotkey v2.0

/**
 * 使用指定的分隔符将字符串分成子字符串数组.并将分隔符补回去
 * 例如：{image}{enter}title:{title}，以{image}分割，转为数组 => ["{image}","{enter}title:{title}"]
 * 
 * @param template 用户模板
 * @param identifier 分隔符
 */
TemplateConvertedToTemplates(template, identifier){
    if (template == identifier){
      templates := [identifier]
      return templates
    } else {
      templates := StrSplit(template, identifier)
  
      For index, value in templates{
        ; 当{image}在开头 及 末尾时，该项为null，所以它(null等于{images})本身就是{images}，不需要补{images}
        if (value == ""){
          continue
        }

        ; 修正：在模板的最后一项为【正常数据】的情况：
        ; 最后一项不需要补{image}，所以跳过
        if (index == templates.Length && value != ""){
          continue
        }

        ; 修正：在模板的最后一项为{image}的情况：
        ; 因为是以{image}分割，所以最后一项为{image}时，值为null，当最后一项为{image}时，它的上一项也会补为{image}，所以 跳过 最后一项的上一项补{image}
        if ((index == templates.Length - 1) && (templates[templates.Length] == "")){
            continue
        }
    
        ; 将非{image}的项后，加上{image}。因为是以{image}分割，所以给个数组项的后一项，都是{image}，将{imgae}给它补回去
        if (value != identifier){
          templates.InsertAt(index + 1, identifier)
        }
      }

      ; 修正：当{image}在开头 及 末尾时，该项为null
      For index, value in templates{
        if (value == "" && index == 1){
            templates[1] := identifier
        }

        if (value == "" && index == templates.Length){
            templates[templates.Length] := identifier
        }
      }

      return templates
    }
}