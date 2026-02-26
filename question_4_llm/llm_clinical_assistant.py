
## importing packages
import pandas as pd
import json
import os
from google import genai
from dotenv import load_dotenv

## extracting environment variable 
## client gets the API key from the environment variable `GEMINI_API_KEY`.
base_dir = os.getcwd()
load_dotenv()

api_key_proj= os.getenv("GEMINI_API_KEY")

client = genai.Client(api_key=api_key_proj)

## establishing data path
data_path = os.path.join(base_dir, "data_in", "ae.csv")

## importing data
ae = pd.read_csv(data_path)

####################
# schema description
####################
schema_description = """
The dataset 'ae' has the following columns:
- USUBJID: unique subject ID
- AETERM: adverse event term, asks about a specific condition or disease
- AESEV: asks severity (MILD, MODERATE, SEVERE)
- AESOC: system organ class, asks about a body system (e.g. 'cardiac','skin')
- AEBODSYS: Body System or Organ Class
- AEDECOD: standardized AE term
- AEOUT: outcome of the AE
- AESTDTC: Start Date/Time of Adverse Event
- AEENDTC: End Date/Time of Adverse Event
- AESTDY: Study Day of Start of Adverse Event
- AEENDY: Study Day of End of Adverse Event

The filter values are to be capitalized
"""

##############
# Offline AI Agent version (mock results)
##############
# class ClinicalTrialDataAgentOffline:
#     def __init__(self, schema_description):
#         self.schema_description = schema_description

#     def parse_question(self, question):
#         """
#         Offline mock of LLM response, mapping simple keywords to column/value pairs.
#         """
#         question_lower = question.lower()
#         ## simple mock rules for demo
#         if "severe" in question_lower:
#             return {"target_column": "AESEV", "filter_value": "SEVERE"}
#         elif "moderate" in question_lower:
#             return {"target_column": "AESEV", "filter_value": "MODERATE"}
#         elif "headache" in question_lower:
#             return {"target_column": "AETERM", "filter_value": "Headache"}
#         elif "nausea" in question_lower:
#             return {"target_column": "AETERM", "filter_value": "Nausea"}
#         else:
#             ## default fallback
#             return {"target_column": "AESEV", "filter_value": "MILD"}

##############
# AI Agent version
##############
class ClinicalTrialDataAgentGemini:
    def __init__(self, schema_description, api_key=None):
        ## schema description
        self.schema_description = schema_description
        ## reading API key
        self.api_key = api_key_proj or os.getenv("GEMINI_API_KEY")
        if not self.api_key:
            raise ValueError("Gemini API key not set. Set GEMINI_API_KEY environment variable.")

    def parse_question(self, question):
        """
        Calls Gemini AI via official Python client and returns JSON:
        { "target_column": "...", "filter_value": "..." }
        """
        ## include system instructions to chatbot, using defined schema
        system_instruction = (
            f"You are a clinical trial data assistant. Convert user questions about adverse events "
            f"into structured JSON for filtering a Pandas dataframe. "
            f"Use this schema: {self.schema_description}. "
            f"Only respond with valid JSON with keys 'target_column' and 'filter_value', do not wrap the response in markdown or code fences."
            )
        
        ## generate a response using the LLM chatbot
        response = client.models.generate_content(
            #model="gemini-2.5-flash",
            model="gemini-3-flash-preview",
            config=genai.types.GenerateContentConfig(system_instruction=system_instruction),
            contents=question
            )

        content = response.text
        try:
            return json.loads(content)
        except json.JSONDecodeError:
            raise ValueError(f"Could not parse JSON from Gemini response: {content}")
        
        
#################
# filter function
#################
def filter_ae_dataframe(ae_df, llm_output):
    ## read targe _column from LLM output
    target_col = llm_output['target_column']
    ## read filter variable from LLM output
    filter_val = llm_output['filter_value']
    
    ## carry out filtering in pandas
    filtered = ae_df[ae_df[target_col] == filter_val]
    ## obtain number unique participants and list of IDs
    unique_subjects = filtered['USUBJID'].nunique()
    subject_ids = filtered['USUBJID'].tolist()
    ## return the output
    return {
        "unique_subject_count": unique_subjects,
        "matching_subject_ids": subject_ids
    }

#########################
# interactive LLM chatbot
#########################
# if __name__ == "__main__":
#     #uncomment for offline chatbot testing
#     #agent = ClinicalTrialDataAgentOffline(schema_description)
#     agent = ClinicalTrialDataAgentGemini(schema_description)
    
#     print("Welcome to the Offline Clinical Trial AE Chatbot!")
#     print("Type 'exit' to quit.\n")
    
#     while True:
#         user_question = input("Enter your question: ")
#         if user_question.lower() in ["exit", "quit"]:
#             print("Goodbye!")
#             break
#         try:
#             llm_out = agent.parse_question(user_question)
#             results = filter_ae_dataframe(ae, llm_out)
#             print("LLM JSON Output (mocked):", llm_out)
#             print("Filtered Results:", results, "\n")
#         except Exception as e:
#             print("Error processing your question:", e, "\n")


def ask_clinical_chatbot(user_question):
    ## initialize Gemini agent
    agent = ClinicalTrialDataAgentGemini(schema_description)

    try:
        ## parse the prompt/question
        llm_out = agent.parse_question(user_question)

        ## filter the AE dataframe
        results = filter_ae_dataframe(ae,llm_out)
        
        ## print the results
        return {"llm_output": llm_out, "filtered_results": results}

    except Exception as e:
        return {"error": str(e)}
    

