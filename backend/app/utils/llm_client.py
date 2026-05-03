"""
LLM客户端封装
统一使用OpenAI格式调用
"""

import json
from typing import Optional, Dict, Any, List
from openai import OpenAI

from ..config import Config


def get_step_llm_config(project, step_key: str) -> Optional[Dict[str, Any]]:
    """
    从项目获取指定步骤的LLM配置，支持全局/单步回退链
    
    Args:
        project: Project对象
        step_key: 步骤标识，如 'step1_graph_build', 'step2_env_setup' 等
        
    Returns:
        配置字典或None（调用方可用LLMClient.from_config处理）
    """
    if not project or not project.llm_configs:
        return None
    
    configs = project.llm_configs
    
    # 优先使用全局配置
    if configs.get("use_global"):
        return configs.get("global")
    
    # 否则使用步骤特定配置
    return configs.get("steps", {}).get(step_key)


class LLMClient:
    """LLM客户端"""
    
    def __init__(
        self,
        api_key: Optional[str] = None,
        base_url: Optional[str] = None,
        model: Optional[str] = None
    ):
        self.api_key = api_key or Config.LLM_API_KEY
        self.base_url = base_url or Config.LLM_BASE_URL
        self.model = model or Config.LLM_MODEL_NAME
        
        if not self.api_key:
            raise ValueError("LLM_API_KEY 未配置")
        
        self.client = OpenAI(
            api_key=self.api_key,
            base_url=self.base_url
        )
    
    @classmethod
    def from_config(cls, config_dict: Optional[Dict[str, Any]]) -> "LLMClient":
        """
        从配置字典创建LLMClient，字段缺失时回退到Config默认值
        """
        if not config_dict:
            return cls()
        return cls(
            api_key=config_dict.get("api_key") or None,
            base_url=config_dict.get("base_url") or None,
            model=config_dict.get("model_name") or None,
        )
    
    def chat(
        self,
        messages: List[Dict[str, str]],
        temperature: float = 0.7,
        max_tokens: int = 4096,
        response_format: Optional[Dict] = None
    ) -> str:
        """
        发送聊天请求
        
        Args:
            messages: 消息列表
            temperature: 温度参数
            max_tokens: 最大token数
            response_format: 响应格式（如JSON模式）
            
        Returns:
            模型响应文本
        """
        kwargs = {
            "model": self.model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
        }
        
        if response_format:
            kwargs["response_format"] = response_format
        
        response = self.client.chat.completions.create(**kwargs)
        return response.choices[0].message.content
    
    def chat_json(
        self,
        messages: List[Dict[str, str]],
        temperature: float = 0.3,
        max_tokens: int = 4096
    ) -> Dict[str, Any]:
        """
        发送聊天请求并返回JSON
        
        Args:
            messages: 消息列表
            temperature: 温度参数
            max_tokens: 最大token数
            
        Returns:
            解析后的JSON对象
        """
        response = self.chat(
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens,
            response_format={"type": "json_object"}
        )
        
        return json.loads(response)
