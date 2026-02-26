with open("llm_clinical_assistant.py") as f:
    code = f.read()
exec(code)

## calling function for three prompts    
ask_clinical_chatbot('Give me the subjects who had Adverse events of Moderate severity')
ask_clinical_chatbot('Give me the subjects who had fatigue as an adverse event')
ask_clinical_chatbot('Give me the subjects who had headache as an adverse event')
